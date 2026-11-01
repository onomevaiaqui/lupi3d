local G=require "geometry"
local m=G.mesh()
-- Tapered nose and tail, broad middle: more rounded silhouette at the same budget.
local body={{-1.175,0.54},{0,0.71},{1.175,0.54}}
for i=1,2 do
    local a,b=body[i],body[i+1]
    G.quad(m,{-a[2],0.33,a[1]},{-b[2],0.33,b[1]},{-b[2],0.71,b[1]},{-a[2],0.71,a[1]},24)
    G.quad(m,{b[2],0.33,b[1]},{a[2],0.33,a[1]},{a[2],0.71,a[1]},{b[2],0.71,b[1]},8)
    G.quad(m,{-a[2],0.71,a[1]},{-b[2],0.71,b[1]},{b[2],0.71,b[1]},{a[2],0.71,a[1]},15)
end
G.quad(m,{-0.54,0.33,-1.175},{-0.54,0.71,-1.175},{0.54,0.71,-1.175},{0.54,0.33,-1.175},8)
G.quad(m,{0.54,0.33,1.175},{0.54,0.71,1.175},{-0.54,0.71,1.175},{-0.54,0.33,1.175},8)
local sections={{-1.12,0.73,0.44},{-0.56,1.16,0.49},{0.05,1.35,0.44},{0.51,1.10,0.46},{1.12,0.73,0.44}}
for i=1,#sections-1 do
    local a,b=sections[i],sections[i+1]
    G.quad(m,{-a[3],a[2],a[1]},{-b[3],b[2],b[1]},{b[3],b[2],b[1]},{a[3],a[2],a[1]},(i==1 or i==4) and 6 or 15)
    G.quad(m,{-0.55,0.72,a[1]},{-0.55,0.72,b[1]},{-b[3],b[2],b[1]},{-a[3],a[2],a[1]},i==2 and 6 or 24)
    G.quad(m,{0.55,0.72,b[1]},{0.55,0.72,a[1]},{a[3],a[2],a[1]},{b[3],b[2],b[1]},i==2 and 6 or 8)
end
for _,x in ipairs({-0.72,0.72}) do for _,z in ipairs({-0.75,0.75}) do
    local wheel=G.box(0.20,0.45,0.43,0,10,10)
    -- Six triangles per wheel; top, underside and inner face are omitted.
    local faces={}
    for i=1,#wheel.f,4 do
        local face=math.floor((i-1)/8)+1
        if face~=1 and face~=6 and face~=(x<0 and 3 or 5) then
            for j=0,3 do faces[#faces+1]=wheel.f[i+j] end
        end
    end
    wheel.f=faces;G.append(m,wheel,x,0.29,z)
end end
G.quad(m,{-0.62,0.36,-1.20},{-0.62,0.44,-1.20},{0.62,0.44,-1.20},{0.62,0.36,-1.20},12)
G.quad(m,{0.62,0.36,1.20},{0.62,0.44,1.20},{-0.62,0.44,1.20},{-0.62,0.36,1.20},12)
for _,x in ipairs({-0.44,0.44}) do
    G.quad(m,{x-0.09,0.48,-1.178},{x-0.09,0.62,-1.178},{x+0.09,0.62,-1.178},{x+0.09,0.48,-1.178},7)
    G.quad(m,{x+0.10,0.51,1.178},{x+0.10,0.67,1.178},{x-0.10,0.67,1.178},{x-0.10,0.51,1.178},9)
end
m.rival=G.mesh()
G.append(m.rival,G.box(1.42,0.4,2.35,7,23,7),0,0.52,0)
G.append(m.rival,G.box(1.0,0.54,1.3,6,22,7),0,0.96,-0.08)
for _,x in ipairs({-0.73,0.73}) do for _,z in ipairs({-0.75,0.75}) do
    local z1,z2=z-0.22,z+0.22
    if x<0 then G.quad(m.rival,{x,0.08,z2},{x,0.53,z2},{x,0.53,z1},{x,0.08,z1},0)
    else G.quad(m.rival,{x,0.08,z1},{x,0.53,z1},{x,0.53,z2},{x,0.08,z2},0) end
end end
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
weld(m);weld(m.rival)
return m
