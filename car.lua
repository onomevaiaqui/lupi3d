local G=require "geometry"
local m=G.mesh()
G.append(m,G.box(1.42,0.38,2.35,8,24,15),0,0.52,0)
local sections={{-1.12,0.73,0.48},{-0.56,1.15,0.49},{0.05,1.33,0.43},{0.51,1.12,0.46},{1.12,0.73,0.48}}
for i=1,#sections-1 do
    local a,b=sections[i],sections[i+1]
    G.quad(m,{-a[3],a[2],a[1]},{-b[3],b[2],b[1]},{b[3],b[2],b[1]},{a[3],a[2],a[1]},(i==1 or i==4) and 6 or 15)
    G.quad(m,{-0.55,0.72,a[1]},{-0.55,0.72,b[1]},{-b[3],b[2],b[1]},{-a[3],a[2],a[1]},i==2 and 6 or 24)
    G.quad(m,{0.55,0.72,b[1]},{0.55,0.72,a[1]},{a[3],a[2],a[1]},{b[3],b[2],b[1]},i==2 and 6 or 8)
end
for _,x in ipairs({-0.72,0.72}) do for _,z in ipairs({-0.75,0.75}) do
    local wheel=G.box(0.20,0.45,0.43,0,10,10)
    -- Remove underside and inner face, hidden by body: eight triangles per wheel.
    local faces={}
    for i=1,#wheel.f,4 do
        local face=math.floor((i-1)/8)+1
        if face~=6 and face~=(x<0 and 3 or 5) then
            for j=0,3 do faces[#faces+1]=wheel.f[i+j] end
        end
    end
    wheel.f=faces;G.append(m,wheel,x,0.29,z)
end end
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
return m
