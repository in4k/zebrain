DIA = 10;
A = 3.5;
K = 5;
W = 3;
rng(0);

linspc = @linspace;
mri_data_for_iso = load('mri');
xspc = linspc(-1,1,128)*30;
zspc = linspc(-1,1,27)*60;
head = isosurface(xspc,xspc,zspc,smooth3(squeeze(mri_data_for_iso.D)),5);
interpolate = @(x,v,xq)interp1(x,v,xq,[],'extrap');
headv = head.vertices;
omega = randn(size(headv,1),1)*2;
omega2 = randn(size(headv,1),1)*.5;

% Init brain
mrist = load('mristack');
mrist = mrist.mristack;
zoomer = @(zoom,x)mod(round(((0:255)-x)/zoom+x),256)+1;
% Init valopallot

xrange = linspc(-3,3,256);
[xgrid,dummy]=ndgrid(xrange);

fig = figure('WindowState','fullscreen', 'MenuBar', 'none', 'ToolBar', 'none','Pointer','custom','PointerShapeCData',nan(16,16));

create_axes=@()axes('position',[0,0,1,1],'visible','off');        


axes1 = create_axes(); 

cmap = @colormap;
mymap = interpolate(1:64,cmap('bone'),1:.1:64);
cmap(mymap);

axes2 = create_axes();

cmap(axes2,mymap(:,[3,1,2]));

cu = rand(9e2,1)*2*pi;
cv = rand(9e2,1)*2*pi;
uu = linspc(0,2*pi,10)';
vv = uu*0;
cu = [cu;uu;uu;vv;vv+2*pi];
cv = [cv;vv;vv+2*pi;uu;uu];


triangles = delaunay(cu,cv);

grix = (cos(-cu)*A+K*sin(W*cv)+DIA).*cos(cv);
gridy = (cos(-cu)*A+K*sin(W*cv)+DIA).*sin(cv);
comp = sin(-cu)*A;

makepatch = @(f,v,c,a,p,s,l,m)patch('faces',f,'vertices',v,'facevertexcdata',c,'facecolor',a,'edgecolor','k','parent',p,'SpecularExponent',5,'SpecularStrength',s,'LineStyle',l,'Marker',m,'MarkerSize',10);                 
mysurf = makepatch(triangles,[grix(:),gridy(:),comp(:)],comp(:)+6,'flat',axes2,0.7,'-','.');

xspc = head.vertices(:,1)*Inf;
hold on;
hscat = scatter3(xspc,xspc,xspc,80,'k.');


hLight = light(axes2);
camera_setup;

% Init viivat
grp = hgtransform('Parent',axes2);
tdata = load('trimesh3d');
meshpatch = makepatch(tdata.tri,[tdata.x(:),tdata.y(:),tdata.z(:)]*3,1,[1,.9,1],grp,1,'none','none');
axes3 = create_axes();            
[grix,gridy] = ndgrid(-1:.01:1);
I=image(axes3,zeros(size(grix)));    
axes3.Visible = 'off';
alphavalues = (grix.^2+gridy.^2)/2;    
alpha(I,alphavalues);    

axes4 = create_axes();
camera_setup;


texts = {'\___\zzz\/zz_\_,-.__\.-.-.zz.~z\/\_�zz/\zzzz\z\`\/z\\z\z\z.','__z__z\__,-.__.,-.z~z/_\/__\/z\z\_\\\z\','4096 bytesz|zMATLABz|zDemosplash 2019','z_z_z~(zvz)~z\z/z~zzvzz','Bits''n''Bites~p01~Brothomstates~Kooma~Orange~CNCD~NoooN','code:pestis/bC!','music:distance/TPOLM','ascii:tes-la/bC!'};
texttimes = [128,192;152,216;644,734;800,896;808,896;1024,1072;1032,1072;1040,1072];
texttimes = reshape([texttimes;texttimes+4],8,[]);
hTexts = arrayfun(@(x,y,z)text(x,y,z,'','VerticalAlign','middle','HorizontalAlign','center','FontWeight','bold','FontName','Courier New','color','w','Interpreter','none'),[10,10,10,20,20,-2,-2,-2],[4,4,4,60,60,-12,-12,-12],[4,-1,-1,30,-10,3,0,-3]);
hTexts(4).Color = 'r';
rands = rand(1,1000);

sum_triggers = cumsum(envs & ~[zeros(7,1),envs(:,1:(end-1))],2);

start_music();
pattern = 0;
while pattern < 35
    cursample = sample();
    sync = @(c)envs(c,cursample);
    beat = cursample/6615;  
    pattern = beat / 32;
    part = pattern / 4;
    scene_counter = sum_triggers(5,cursample);
    cx = cos(part)*50+127;
    cy = sin(part*1.1)*50+127;
    
    time = pi*pattern/34.5;
    fade = interpolate([0,224,240,258,259,1024,1104,1120],[0,.8,0,0,1,1,0,0],beat)^.5;
    h=xgrid+xgrid'*1i;
    for f=0:2
        comp=0;
        for kind=[1:3,5]
            comp=comp+1./(h-.7*sin(time*kind)*exp(1i*kind*(scene_counter*2+1)+f));
        end
        h=h-3./comp;
    end
    comp = 256-sqrt(abs(comp))*200;
    
    brain_index = part*20/9+1;
    alphaBrain = mod(brain_index,1);
    ind = floor(brain_index);
    comp = comp+max(double(mrist(:,:,ind))*(1-alphaBrain)+double(mrist(:,:,ind+1))*alphaBrain,interpolate([0,2,2.5,3,6,8],[0,0,1,1,0,0],part)*255);    
    zoom = sync(6).*.1+interpolate([0,34],[1.2,1],pattern);
    for angle = 1:5     
        comp = comp+comp(zoomer(zoom,cx),zoomer(zoom+sync(7)*.3,cy));       
        zoom = sqrt(zoom);
    end
       
    image(axes1,tanh((comp/80*fade+sync(1))/64)*640);    
    axes1.Visible = 'off';
    
    angle = beat/100 + scene_counter + 1;                        

    camera_position = [(DIA+K*sin(W*angle))*cos(angle),(DIA+K*sin(W*angle))*sin(angle),0];
    campos(axes2,camera_position);        
    campos(axes4,camera_position);
    camlight(hLight,'HEADLIGHT'); 
    
    viewmat = view(axes2);
    screen_z = viewmat * [0;0;1;0];
    xy = screen_z(1:2)/screen_z(3);

    for index = 1:length(texts)
        str = texts{index};
        not_empty = str ~= '~' & str ~= 'z';
        string_sync = interpolate(texttimes(index,:),[1,0,0,1],beat);
        offset = rands(1:length(str))*.5;
        str_indices = not_empty & string_sync>(.5-offset);
        str(str_indices) = randi([33,47],1,sum(str_indices));
        str(not_empty & string_sync>(1-offset) | str == 'z') = 32;
        hTexts(index).String = split(str,'~');   
        hTexts(index).Rotation = -atan2d(xy(1),xy(2));
        hTexts(index).FontSize = fig.Position(3)/50;
    end
    
    bar = sin(pi*part)^2^.1;      
    mysurf.FaceAlpha = interpolate([0,258,258.1,448,512,1280],[0,0,.8,.8,0,0],beat);
    mysurf.EdgeAlpha = interpolate([0,1,1.5,4,5,10],[0,0,1,1,0,0],part);
    mysurf.AmbientStrength = min(sync(5)+0.5,1);
    time = max(part-3,0);
    blending = min(max(part-4,0),1)^.2;
    angle = omega*time;  
    point_b = [(DIA+K*sin(W*angle)).*cos(angle),(DIA+K*sin(W*angle)).*sin(angle),(time+sync(7)*.3)*sin(omega2*time)*A];
    blended = headv * blending + point_b * (1-blending);
    muljuttu = blended + interpolate([0,6,9],[0,0,3],part)*sin(blended*.5*sin(time+[.2,1.1,.3;.4,.3,.9;1.2,.5,.1])+[.3,.4,.5]*time);
    hscat.XData = muljuttu(:,1);
    hscat.YData = muljuttu(:,2); 
    hscat.ZData = muljuttu(:,3);
    draw();
    meshpatch.FaceAlpha = interpolate([0,5,5.5,7.34,7.4,9],[0,0,.4,.4,0,0],part);
    grp.Matrix = makehgtform('yrotate',pi/2)*makehgtform('zrotate',pattern);
end

close all
