local G=require "geometry"
local m=G.mesh()
-- Tapered nose/tail and curved cabin, built with shared XYZ cross-sections.
local body={{-1.175,0.54},{0,0.75},{1.175,0.54}}
for i=1,2 do
    local a,b=body[i],body[i+1]
    G.quad(m,{-a[2],0.33,a[1]},{-b[2],0.33,b[1]},{-b[2],0.71,b[1]},{-a[2],0.71,a[1]},24)
    G.quad(m,{b[2],0.33,b[1]},{a[2],0.33,a[1]},{a[2],0.71,a[1]},{b[2],0.71,b[1]},8)
    G.quad(m,{-a[2],0.71,a[1]},{-b[2],0.71,b[1]},{b[2],0.71,b[1]},{a[2],0.71,a[1]},15)
end
G.quad(m,{-0.54,0.33,-1.175},{-0.54,0.71,-1.175},{0.54,0.71,-1.175},{0.54,0.33,-1.175},8)
G.quad(m,{0.54,0.33,1.175},{0.54,0.71,1.175},{-0.54,0.71,1.175},{-0.54,0.33,1.175},8)
local sections={{-1.12,0.73,0.44},{-0.72,0.80,0.50},{-0.43,1.16,0.49},{0.15,1.35,0.45},{0.60,1.10,0.46},{1.12,0.73,0.44}}
for i=1,#sections-1 do
    local a,b=sections[i],sections[i+1]
    G.quad(m,{-a[3],a[2],a[1]},{-b[3],b[2],b[1]},{b[3],b[2],b[1]},{a[3],a[2],a[1]},(i==2 or i==4) and 1 or 15)
    G.quad(m,{-0.55,0.72,a[1]},{-0.55,0.72,b[1]},{-b[3],b[2],b[1]},{-a[3],a[2],a[1]},(i==3 or i==4) and 22 or 24)
    G.quad(m,{0.55,0.72,b[1]},{0.55,0.72,a[1]},{a[3],a[2],a[1]},{b[3],b[2],b[1]},(i==3 or i==4) and 6 or 8)
end
-- Hexagonal outer tire profile + two 3D end caps, still six triangles/wheel.
local function tires(m,track,axle,height,length)
for _,x in ipairs({-track,track}) do for _,z in ipairs({-axle,axle}) do
    local outside=x+(x<0 and -0.1 or 0.1)
    local inside=x+(x<0 and 0.1 or -0.1)
    local n=#m.v/3
    local function point(px,py,pz)
        return {px,py*height,z+pz*length}
    end
    for _,p in ipairs({point(outside,0.54,-0.13),point(outside,0.54,0.13),point(outside,0.29,0.27),
        point(outside,0.04,0.13),point(outside,0.04,-0.13),point(outside,0.29,-0.27),
        point(inside,0.40,0.13),point(inside,0.40,-0.13)}) do
        for _,v in ipairs(p) do m.v[#m.v+1]=v end
    end
    local function triangle(a,b,c,color,reverse)
        if reverse then b,c=c,b end
        for _,v in ipairs({n+a,n+b,n+c,color}) do m.f[#m.f+1]=v end
    end
    for i=2,5 do triangle(1,i,i+1,0,x<0) end
    triangle(2,3,7,10,x>0);triangle(6,1,8,10,x>0)
end end
end
tires(m,0.72,0.75,1,1)
G.quad(m,{-0.62,0.36,-1.20},{-0.62,0.44,-1.20},{0.62,0.44,-1.20},{0.62,0.36,-1.20},12)
G.quad(m,{0.62,0.36,1.20},{0.62,0.44,1.20},{-0.62,0.44,1.20},{-0.62,0.36,1.20},12)
for _,x in ipairs({-0.44,0.44}) do
    G.quad(m,{x-0.09,0.48,-1.178},{x-0.09,0.62,-1.178},{x+0.09,0.62,-1.178},{x+0.09,0.48,-1.178},7)
    G.quad(m,{x+0.12,0.59,1.178},{x,0.70,1.178},{x-0.12,0.59,1.178},{x,0.48,1.178},9)
end
-- Weld exact shared XYZ positions once at load time, reducing per-frame projection.
local function build(sections,color,wheelHeight,axle,lights,roofColor,bumperColor,lightWidth)
    local car=G.mesh()
    local function corners(s)
        local z,w,b,h,roof,glass=table.unpack(s)
        return {{-w,b,z},{w,b,z},{w,h,z},{roof,h,z},{roof,glass,z},
            {-roof,glass,z},{-roof,h,z},{-w,h,z}}
    end
    local a=corners(sections[1])
    G.quad(car,a[1],a[8],a[3],a[2],color)
    if sections[1][6]>sections[1][4] then G.quad(car,a[7],a[6],a[5],a[4],1) end
    for i=2,#sections do
        local b=corners(sections[i])
        for j=2,8 do
            local k=j%8+1
            local shade=color
            if j==4 or j==6 then shade=22
            elseif j==5 then shade=sections[i][7] and 1 or roofColor
            elseif j==8 then shade=color+16 end
            G.quad(car,a[j],a[k],b[k],b[j],shade)
        end
        a=b
    end
    G.quad(car,a[2],a[3],a[8],a[1],color)
    G.quad(car,a[4],a[5],a[6],a[7],6)
    tires(car,0.82,axle,wheelHeight/0.54,1)
    local nose=sections[#sections][1]+0.005
    G.quad(car,{0.6,0.34,nose},{0.6,0.44,nose},{-0.6,0.44,nose},{-0.6,0.34,nose},bumperColor)
    for i=1,lights do
        local x=(i-(lights+1)/2)*(lights==2 and 0.86 or 0.29)
        G.quad(car,{x+lightWidth,0.49,nose},{x+lightWidth,0.62,nose},
            {x-lightWidth,0.62,nose},{x-lightWidth,0.49,nose},9)
    end
    G.weld(car)
    return car
end
G.weld(m)
local fiat=build({
    {-1.02,0.67,0.31,0.73,0.55,0.73},{-0.89,0.68,0.31,0.73,0.53,1.29,true},
    {0.19,0.69,0.31,0.73,0.52,1.28},{0.57,0.68,0.31,0.70,0.56,0.74,true},
    {1.02,0.65,0.31,0.66,0.53,0.66}
},7,0.45,0.68,2,7,10,0.145)
local gurgel=build({
    {-1.08,0.67,0.48,0.81,0.56,0.81},{-0.94,0.69,0.48,0.81,0.56,1.48,true},
    {0.19,0.69,0.48,0.81,0.55,1.48},{0.55,0.69,0.48,0.80,0.58,0.80,true},
    {1.07,0.58,0.43,0.65,0.49,0.65}
},14,0.59,0.72,2,13,10,0.09)
G.append(gurgel,G.box(0.48,0.50,0.22,0,10,0),0,0.92,-1.17)
G.weld(gurgel)
local puma=build({
    {-1.44,0.69,0.30,0.62,0.56,0.62},{-0.99,0.74,0.30,0.63,0.58,0.66},
    {-0.68,0.75,0.30,0.65,0.51,1.03,true},{-0.08,0.76,0.30,0.65,0.50,1.04},
    {0.57,0.75,0.30,0.64,0.57,0.65,true},{1.47,0.65,0.30,0.62,0.52,0.62}
},12,0.46,0.92,4,12,27,0.10)
-- Straight hood, three-box sedan cabin and short trunk: Chevette.
local chevette=build({
    {-1.30,0.66,0.31,0.68,0.53,0.68},{-0.75,0.70,0.31,0.70,0.53,0.72},
    {-0.43,0.70,0.31,0.71,0.49,1.19,true},{0.38,0.70,0.31,0.71,0.49,1.19},
    {0.78,0.68,0.31,0.67,0.54,0.69,true},{1.30,0.63,0.31,0.63,0.52,0.63}
},8,0.46,0.83,2,8,12,0.15)
-- Split-window Kombi: dedicated silhouette, inset windows and faceted round trim.
local kombi=G.mesh()
local function panel(a,b,c,d,color,nx,ny,nz)
    local ux,uy,uz=b[1]-a[1],b[2]-a[2],b[3]-a[3]
    local vx,vy,vz=c[1]-a[1],c[2]-a[2],c[3]-a[3]
    if (uy*vz-uz*vy)*nx+(uz*vx-ux*vz)*ny+(ux*vy-uy*vx)*nz<0 then b,d=d,b end
    G.quad(kombi,a,b,c,d,color)
end
for _,side in ipairs({-1,1}) do
    local x=side*0.75
    panel({x,0.34,-1.48},{x,0.34,1.48},{x,0.99,1.48},{x,0.99,-1.48},side<0 and 17 or 1,side,0,0)
    local function edge(t,y)
        local f=(y-0.99)/0.61
        return {side*(0.75-0.11*f),y,(-1.48+0.10*f)+(2.96-0.43*f)*t}
    end
    local function strip(a,b,lo,hi,color)
        panel(edge(a,lo),edge(b,lo),edge(b,hi),edge(a,hi),color,side,0,0)
    end
    strip(0,1,0.99,1.10,1);strip(0,1,1.51,1.60,1)
    -- Cut the glass into the body instead of layering it over large triangles.
    local edges={0,0.045,0.32,0.365,0.64,0.685,0.955,1}
    for i=1,#edges-1 do strip(edges[i],edges[i+1],1.10,1.51,i%2==0 and 10 or 1) end
end

panel({-0.75,0.34,-1.48},{0.75,0.34,-1.48},{0.75,0.99,-1.48},{-0.75,0.99,-1.48},17,0,0,-1)

panel({-0.64,1.60,-1.38},{-0.51,1.70,-1.30},{-0.51,1.70,1.08},{-0.64,1.60,1.15},12,0,1,0)
panel({-0.51,1.70,-1.30},{0.51,1.70,-1.30},{0.51,1.70,1.08},{-0.51,1.70,1.08},9,0,1,0)
panel({0.51,1.70,-1.30},{0.64,1.60,-1.38},{0.64,1.60,1.15},{0.51,1.70,1.08},12,0,1,0)
panel({-0.64,1.60,1.15},{0.64,1.60,1.15},{0.51,1.70,1.08},{-0.51,1.70,1.08},12,0,1,1)
panel({0.64,1.60,-1.38},{-0.64,1.60,-1.38},{-0.51,1.70,-1.30},{0.51,1.70,-1.30},12,0,1,-1)
-- Front glass is also a tessellated surface, with an actual center pillar.
local function front(u,y)
    local f=(y-0.99)/0.61
    return {u*(0.75-0.11*f),y,1.48-0.33*f}
end
local function windshield(a,b,lo,hi,color)
    panel(front(a,lo),front(b,lo),front(b,hi),front(a,hi),color,0,0,1)
end
windshield(-1,1,0.99,1.08,1);windshield(-1,1,1.51,1.60,1)
local spans={-1,-0.90,-0.045,0.045,0.90,1}
for i=1,5 do windshield(spans[i],spans[i+1],1.08,1.51,i%2==0 and 10 or 1) end
local function rear(u,y)
    local f=(y-0.99)/0.61
    return {u*(0.75-0.11*f),y,-1.48+0.10*f}
end
local function rearPanel(a,b,lo,hi,color)
    panel(rear(a,lo),rear(b,lo),rear(b,hi),rear(a,hi),color,0,0,-1)
end
rearPanel(-1,1,0.99,1.13,1);rearPanel(-1,1,1.48,1.60,1)
rearPanel(-1,-0.76,1.13,1.48,1);rearPanel(0.76,1,1.13,1.48,1)
rearPanel(-0.76,0.76,1.13,1.48,10)
-- Tessellated nose defines the V without overlapping painted faces.
local function frontTriangle(a,b,c,color)
    if (b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1])<0 then b,c=c,b end
    local n=#kombi.v/3
    for _,p in ipairs({a,b,c}) do for _,v in ipairs(p) do kombi.v[#kombi.v+1]=v end end
    for _,v in ipairs({n+1,n+2,n+3,color}) do kombi.f[#kombi.f+1]=v end
end
frontTriangle({-0.75,0.34,1.48},{0.75,0.34,1.48},{0,0.66,1.48},1)
frontTriangle({-0.75,0.99,1.48},{0,0.66,1.48},{0.75,0.99,1.48},12)
panel({-0.075,0.84,1.49},{0,0.77,1.49},{0.075,0.84,1.49},{0,0.91,1.49},9,0,0,1)
for _,side in ipairs({-1,1}) do
    local function p(x,y)return {side*x,y,1.48}end
    local B,C,E=p(0.75,0.34),p(0.75,0.99),p(0,0.66)
    local L,D,R,U=p(0.40,0.62),p(0.53,0.49),p(0.66,0.62),p(0.53,0.75)
    -- Cut the lamp out of the nose: no coplanar overlays for the painter sorter.
    for _,t in ipairs({{B,C,R},{C,U,R},{C,E,U},{E,L,U},{E,B,L},{B,D,L},{B,R,D}})do
        frontTriangle(t[1],t[2],t[3],1)
    end
    panel(L,D,R,U,9,0,0,1)
    local x=side*0.53
    panel({x-0.065,0.85,1.49},{x,0.79,1.49},{x+0.065,0.85,1.49},{x,0.91,1.49},8,0,0,1)
    panel({x-0.07,0.51,-1.49},{x+0.07,0.51,-1.49},{x+0.07,0.67,-1.49},{x-0.07,0.67,-1.49},7,0,0,-1)
end
for _,z in ipairs({-1.50,1.50}) do
    panel({-0.79,0.34,z},{0.79,0.34,z},{0.79,0.43,z},{-0.79,0.43,z},9,0,0,z)
end
-- Six-sided tire silhouettes with inset light hubcaps, not overlapping decals.
local function wheelTriangle(a,b,c,color,side)
    local ux,uy,uz=b[1]-a[1],b[2]-a[2],b[3]-a[3]
    local vx,vy,vz=c[1]-a[1],c[2]-a[2],c[3]-a[3]
    if (uy*vz-uz*vy)*side<0 then b,c=c,b end
    local n=#kombi.v/3
    for _,p in ipairs({a,b,c})do for _,v in ipairs(p)do kombi.v[#kombi.v+1]=v end end
    for _,v in ipairs({n+1,n+2,n+3,color})do kombi.f[#kombi.f+1]=v end
end
for _,side in ipairs({-1,1}) do for _,z in ipairs({-0.94,0.94}) do
    local function p(dy,dz)return {side*0.86,dy,z+dz}end
    local a,b,c,d,e,f=p(0.59,-0.14),p(0.59,0.14),p(0.32,0.29),p(0.05,0.14),p(0.05,-0.14),p(0.32,-0.29)
    local u,v,w,x=p(0.49,0),p(0.32,0.17),p(0.15,0),p(0.32,-0.17)
    for _,t in ipairs({{a,b,u},{b,v,u},{b,c,v},{c,d,v},{d,w,v},{d,e,w},{e,x,w},{e,f,x},{f,a,x},{a,u,x}})do
        wheelTriangle(t[1],t[2],t[3],0,side)
    end
    panel(u,v,w,x,9,side,0,0)
end end
G.weld(kombi)
m.models={
    {name="FUSCA",trait="EQUILIBRADO",mesh=m,speed=15,accel=7,steer=1.5,grass=5},
    {name="FIAT 147",trait="AGIL NAS CURVAS",mesh=fiat,speed=14.3,accel=7.5,steer=1.7,grass=5},
    {name="GURGEL X-12",trait="MELHOR NA GRAMA",mesh=gurgel,speed=13.8,accel=7,steer=1.52,grass=7},
    {name="PUMA GTB TUBARAO",trait="MAIOR VELOCIDADE",mesh=puma,speed=16.3,accel=7.2,steer=1.4,grass=5},
    {name="CHEVETTE",trait="ARRANCADA FORTE",mesh=chevette,speed=15.4,accel=7.8,steer=1.48,grass=5},
    {name="KOMBI",trait="ROBUSTA / +20 VIDA",mesh=kombi,speed=13.5,accel=6.7,steer=1.42,grass=5.8,hp=120}
}
for _,model in ipairs(m.models) do
    local faces=model.mesh.f
    for i=4,#faces,4 do
        if faces[i]==22 then faces[i]=10
        elseif faces[i]==6 then faces[i]=1 end
    end
end
return m
