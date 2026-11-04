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
local function weld(mesh)
    local positions,vertices,remap={},{},{}
    for i=1,#mesh.v,3 do
        local x,y,z=mesh.v[i],mesh.v[i+1],mesh.v[i+2]
        positions[x]=positions[x] or {};local ys=positions[x]
        ys[y]=ys[y] or {};local zs=ys[y]
        local index=zs[z]
        if not index then
            index=#vertices/3+1;zs[z]=index
            vertices[#vertices+1]=x;vertices[#vertices+1]=y;vertices[#vertices+1]=z
        end
        remap[(i+2)/3]=index
    end
    for i=1,#mesh.f,4 do for j=0,2 do mesh.f[i+j]=remap[mesh.f[i+j]] end end
    mesh.v=vertices
end
local function build(sections,color,wheelHeight,axle,lights,roofColor,bumperColor,lightWidth)
    local car=G.mesh()
    local function corners(s)
        local z,w,b,h,roof,glass=table.unpack(s)
        return {{-w,b,z},{w,b,z},{w,h,z},{roof,h,z},{roof,glass,z},
            {-roof,glass,z},{-roof,h,z},{-w,h,z}}
    end
    local a=corners(sections[1])
    G.quad(car,a[1],a[8],a[3],a[2],color)
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
    G.quad(car,a[7],a[6],a[5],a[4],6)
    tires(car,0.82,axle,wheelHeight/0.54,1)
    local nose=sections[#sections][1]+0.005
    G.quad(car,{0.6,0.34,nose},{0.6,0.44,nose},{-0.6,0.44,nose},{-0.6,0.34,nose},bumperColor)
    for i=1,lights do
        local x=(i-(lights+1)/2)*(lights==2 and 0.86 or 0.29)
        G.quad(car,{x+lightWidth,0.49,nose},{x+lightWidth,0.62,nose},
            {x-lightWidth,0.62,nose},{x-lightWidth,0.49,nose},9)
    end
    weld(car)
    return car
end
weld(m)
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
weld(gurgel)
local puma=build({
    {-1.44,0.69,0.30,0.62,0.56,0.62},{-0.99,0.74,0.30,0.63,0.58,0.66},
    {-0.68,0.75,0.30,0.65,0.51,1.03,true},{-0.08,0.76,0.30,0.65,0.50,1.04},
    {0.57,0.75,0.30,0.64,0.57,0.65,true},{1.47,0.65,0.30,0.62,0.52,0.62}
},12,0.46,0.92,4,12,27,0.10)
m.models={
    {name="FUSCA",trait="EQUILIBRADO",mesh=m,speed=15,accel=7,steer=1.5,grass=5},
    {name="FIAT 147",trait="AGIL NAS CURVAS",mesh=fiat,speed=14.3,accel=7.5,steer=1.7,grass=5},
    {name="GURGEL X-12",trait="MELHOR NA GRAMA",mesh=gurgel,speed=13.8,accel=7,steer=1.52,grass=7},
    {name="PUMA GTB TUBARAO",trait="MAIOR VELOCIDADE",mesh=puma,speed=16.3,accel=7.2,steer=1.4,grass=5}
}
for _,model in ipairs(m.models) do
    local faces=model.mesh.f
    for i=4,#faces,4 do
        if faces[i]==22 then faces[i]=10
        elseif faces[i]==6 then faces[i]=1 end
    end
end
return m
