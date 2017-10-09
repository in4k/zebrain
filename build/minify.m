function ret = minify(code,extrasymbols)
    tokens = regexp(code,'[;\n]\s*(\w+)[^=\n]*=','tokens');
    t2 = cell(1,length(tokens));
    for i = 1:length(tokens)
        t2{i} = tokens{i}{1};
    end
    t2 = unique(t2);
    reserved = {'if','else','elseif','end','for','function','(',')'};
    t2 = t2(~ismember(t2,reserved));
    t2 = [t2 extrasymbols];
    for i = 1:length(t2)
        pattern = ['(\W+)' t2{i} '(?=\W)'];
        c = ['$1symbol' getcode(i)];
        code = regexprep(code,pattern,c);
    end
    code = regexprep(code,'(\W+)symbol(\w+)(?=\W)','$1$2');
    code = regexprep(code,'([^%]+)[^\n]*','$1\n');
    code = regexprep(code,'\n',';');
    code = regexprep(code,'\s+',' ');
    for i = 1:3
        code = regexprep(code,'(\W)\s(\W)','$1$2');    
        code = regexprep(code,'(\w)\s(\W)','$1$2');    
        code = regexprep(code,'(\W)\s(\w)','$1$2');        
    end
    code = regexprep(code,';+',';');
    code = regexprep(code,'end;','end\n');    
    ret = code;
end

function ret = getcode(i)
    valids = [char(97:122) char(65:90)]; % a-z A-Z, the variable
    % has to start with a letter. We don't need underscores and digits
    % because they can only be used when there is two or more letters
    % and if we hit two letters, it's unlikely we hit three
    
    n = length(valids);        
    ret = [];
    for j = 1:10
        if (i <= n)            
            ret = [valids(i) ret];    
            return;
        else
            c = mod(i-1,n);
            ret = [valids(c+1) ret];        
            i = (i -1- c)/n;               
        end
    end
end