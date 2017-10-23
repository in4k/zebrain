% This is a MATLAB port of the SoundBox player-small.js
% from https://github.com/mbitsnbites/soundbox/
% Ported by: Veikko Sariola, 2017
%
% Original copyright: (c) 2011-2013 Marcus Geelnard
%
% This software is provided 'as-is', without any express or implied
% warranty. In no event will the authors be held liable for any damages
% arising from the use of this software.
%
% Permission is granted to anyone to use this software for any purpose,
% including commercial applications, and to alter it and redistribute it
% freely, subject to the following restrictions:
%
% 1. The origin of this software must not be misrepresented; you must not
%    claim that you wrote the original software. If you use this software
%    in a product, an acknowledgment in the product documentation would be
%    appreciated but is not required.
%
% 2. Altered source versions must be plainly marked as such, and must not be
%    misrepresented as being the original software.
%
% 3. This notice may not be removed or altered from any source
%    distribution.

function [mMixBuf,envBufs] = player(song)

    x = (0:44099)/44100;
    % Precalculate oscillators into a table; this is much faster than
    % using lambdas in matlab
    % Oscillators: 1 = sine, 2 = square, 3 = sawtooth, 4 = triangle
    oscPrecalc = [sin(x*2*pi);(x < .5)*2-1;2 * x - 1;1-abs(x*4-2)];
    getnotefreq = @(n) .003959503758 * 2^((n - 128) / 12);    

    % Init iteration state variables
    mLastRow = song.endPattern;

    % Prepare song info
    mNumSamples = song.rowLen * song.patternLen * (mLastRow + 1);

    numChannels = length(song.songData);
    
    % Create work buffer (initially cleared)
    mMixBuf = zeros(2,mNumSamples);
    envBufs = zeros(numChannels,mNumSamples);
    
    for mCurrentCol = 0:numChannels-1   
        mCurrentCol
        % Put performance critical items in local variables
        chnBuf = zeros(2,mNumSamples);
        instr = song.songData{mCurrentCol+1};
        rowLen = song.rowLen;
        patternLen = song.patternLen;

        % Clear effect state
        low = 0;
        band = 0;        
        filterActive = 0;        

        % Clear note cache.
        noteCache = {};

        % Patterns
        for p = 0:mLastRow
            cp = indexArray(instr{2},p+1);            
                       
            % Pattern rows
            for row = 0:(patternLen-1)
                % Execute effect command.                                
                cmdNo = indexArray(indexArray(indexArray(instr{3},cp),2),row+1);
                if cmdNo
                    instr{1}(cmdNo) = indexArray(instr{3}{cp}{2},row + patternLen+1);

                    % Clear the note cache since the instrument has changed
                    if cmdNo < 16
                        noteCache = {};
                    end
                end
                

                % Put performance critical instrument properties in local variables
                oscLFO = instr{1}(16)+1;
                lfoAmt = instr{1}(17) / 512;
                lfoFreq = 2^(instr{1}(18) - 9) / rowLen;
                fxLFO = instr{1}(19);
                fxFilter = instr{1}(20);
                fxFreq = instr{1}(21) * 43.23529 * pi / 44100;
                q = 1 - instr{1}(22) / 255;
                dist = instr{1}(23) * 1e-5;
                drive = instr{1}(24) / 32;
                panAmt = instr{1}(25) / 512;
                panFreq = 2*pi * 2^(instr{1}(26) - 9) / rowLen;
                dlyAmt = instr{1}(27) / 255;
                dly = bitor(instr{1}(28) * rowLen,1)-1; % Must be an even number

                % Calculate start sample number for this row in the pattern
                rowStartSample = (p * patternLen + row) * rowLen;

                % Generate notes for this pattern row
                for col=0:3
                    n = indexArray(indexArray(indexArray(instr{3},cp),1),row + col * patternLen+1);
                    if n
                        if isempty(indexArray(noteCache,n+1))
                            noteCache{n+1} = createNote(instr, n, rowLen);
                        end

                        % Copy note from the note cache
                        noteBuf = noteCache{n+1};                           
                        range = rowStartSample+1:rowStartSample+length(noteBuf);
                        chnBuf(1,range) = chnBuf(1,range)+noteBuf(1,:);                        
                        envBufs(mCurrentCol+1,range) = envBufs(mCurrentCol+1,range)+noteBuf(2,:);                                                
                    end
                end
                                                
                
                % Perform effects for this pattern row
                for k = rowStartSample * 2:2:(rowStartSample + rowLen-1) * 2

                    % We only do effects if we have some sound input
                    if filterActive || chnBuf(k+1)                                              
                        
                        % Dry mono-sample                        
                        tmpsample = chnBuf(k+1);                    
                        % State variable filter
                        f = fxFreq;
                        if fxLFO
                            f = f * (oscPrecalc(oscLFO,floor(mod(lfoFreq * k,1)*44100+1)) * lfoAmt + 0.5);
                        end
                        f = 1.5 * sin(f);
                        low = low + f * band;
                        high = q * (tmpsample - band) - low;
                        band = band + f * high;
                        if fxFilter == 3
                            tmpsample = band;
                        elseif fxFilter == 1 
                            tmpsample = high;
                        else
                            tmpsample = low;
                        end

                        % Distortion
                        if dist>0
                            tmpsample = tmpsample * dist;
                            if tmpsample < 1
                                if tmpsample > -1
                                    tmpsample = oscPrecalc(1,floor(mod(tmpsample*.25,1)*44100+1));
                                else
                                    tmpsample = -1;
                                end
                            else
                                tmpsample = 1;
                            end                                    
                            tmpsample = tmpsample / dist;
                        end

                        % Drive
                        tmpsample = tmpsample * drive;

                        % Is the filter active (i.e. still audiable)?
                        filterActive = tmpsample * tmpsample > 1e-5;

                        % Panning
                        t = sin(panFreq * k) * panAmt + 0.5;
                        chnBuf(k+1) = tmpsample * (1 - t);
                        chnBuf(k+2) = tmpsample * t;    
                    
                    end
                end
                
                start = max(rowStartSample * 2,dly);                
                
                % Perform delay. This could have been done in the previous
                % loop, but it was slower than doing a second loop
                for k = start:2:(rowStartSample + rowLen-1) * 2
                    chnBuf(k+1)=chnBuf(k+1)+chnBuf(k-dly+2) * dlyAmt;
                    chnBuf(k+2)=chnBuf(k+2)+chnBuf(k-dly+1) * dlyAmt;
                end
            end
        end    
        
        mMixBuf = mMixBuf + chnBuf;
    end
    
    function r=indexArray(a,n)
        r = [];
        if ~isempty(a) && ~isempty(n) && n > 0 && length(a) >= n
            if iscell(a)
                r=a{n};
            else
                r=a(n);
            end
        end
    end
        
    function noteBuf = createNote(instr,n,rowLen)
        osc1 = instr{1}(1)+1;
        o1vol = instr{1}(2);
        o1xenv = instr{1}(4);
        osc2 = instr{1}(5)+1;
        o2vol = instr{1}(6);
        o2xenv = instr{1}(9);
        noiseVol = instr{1}(10);
        attack = instr{1}(11)^2 * 4;
        sustain = instr{1}(12)^2 * 4;
        release = instr{1}(13)^2 * 4;
        releaseInv = 1 / release;

        noteBuf = zeros(2,attack + sustain + release);
        

        c1 = 0;
        c2 = 0;

        % Generate one note (attack + sustain + release)
        o1t = getnotefreq(n + instr{1}(3) - 128);
        o2t = getnotefreq(n + instr{1}(7) - 128) * (1 + .0008 * instr{1}(8));
        
        for jj = 0:attack + sustain + release-1

            % Envelope
            e = 1;
            if jj < attack
                e = jj / attack;
            elseif jj >= attack + sustain
                e = e - (jj - attack - sustain) * releaseInv;
            end

            % Oscillator 1
            time = o1t;
            if o1xenv
                time = time * e * e;
            end
            c1 = c1 + time;
            sample = oscPrecalc(osc1,floor(mod(c1,1)*44100+1)) * o1vol;

            % Oscillator 2
            time = o2t;
            if o2xenv
                time = time * e * e;
            end

            c2 = c2 + time;
            sample = sample + oscPrecalc(osc2,floor(mod(c2,1)*44100+1)) * o2vol;

            % Noise oscillator
            if noiseVol>0
                sample = sample + (2 * rand - 1) * noiseVol;
            end

            % Add to (mono) channel buffer
            noteBuf(1,jj+1) = 80 * sample * e;       
            noteBuf(2,jj+1) = e;                   
        end          
    end
end