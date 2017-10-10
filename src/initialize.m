closeall = @() close('all');
closeall();

N={'units','normalized','position',[0 0 1 1]};
N2={'visible','off'};
figure(N{:});
a3=axes(N{:},N2{:});  
hText = text(0,0,'','FontSize',60,'FontWeight','bold');

a2=axes(N{:},N2{:});            
[x,y] = ndgrid(-1:.01:1);
I=image(zeros(size(x)));    
set(gca,'visible','off');
alphavalues = (x.^2+y.^2).^1.5/2.8284;    
alpha(I,alphavalues);    

u = rand(9e2,1)*2*pi;
v = rand(9e2,1)*2*pi;
uu = linspace(0,2*pi,10)';
vv = uu*0;
u = [u;uu;uu;vv;vv+2*pi];
v = [v;vv;vv+2*pi;uu;uu];
D = 10;
A = 3.5;
K = 5;
W = 3;

a1=axes(N{:},N2{:});        
tri = delaunay(u,v);
x = (cos(-u)*A+K*sin(W*v)+D).*cos(v);
y = (cos(-u)*A+K*sin(W*v)+D).*sin(v);
z = sin(-u)*A;
trisurf(tri,x,y,z,'LineWidth',2);                  
colormap bone    
hLight = camlight;
camup([1 0 1]);
daspect([1 1 1]);        
camproj('perspective')
camva(75);
camtarget([5 5 1]);