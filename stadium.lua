-- Experimental stadium scene, original XYZ geometry inspired by the supplied photo.
local G=require "geometry"
local S={}
S.tree=G.mesh()
local function crown(x,y,z,rx,ry,rz)
    local n=#S.tree.v/3
    for _,p in ipairs({{-rx,0,0},{0,0,rz},{rx,0,0},{0,0,-rz},{0,ry,0},{0,-ry*0.55,0}}) do
        S.tree.v[#S.tree.v+1]=p[1]+x;S.tree.v[#S.tree.v+1]=p[2]+y;S.tree.v[#S.tree.v+1]=p[3]+z
    end
    local f={1,2,5,2,2,3,5,3,3,4,5,2,4,1,5,3,2,1,6,18,3,2,6,19,4,3,6,18,1,4,6,19}
    for i=1,#f,4 do
        S.tree.f[#S.tree.f+1]=f[i]+n;S.tree.f[#S.tree.f+1]=f[i+1]+n;S.tree.f[#S.tree.f+1]=f[i+2]+n;S.tree.f[#S.tree.f+1]=f[i+3]
    end
end
crown(0,2.8,0,1.25,1.15,1.2);crown(0.8,2.55,0.1,0.9,0.9,1);crown(-0.65,2.45,0.25,0.85,0.85,0.9)
G.quad(S.tree,{-0.17,0,-0.17},{-0.17,2.4,-0.17},{0.17,2.4,-0.17},{0.17,0,-0.17},13)
G.quad(S.tree,{0.17,0,-0.17},{0.17,2.4,-0.17},{0.17,2.4,0.17},{0.17,0,0.17},29)
S.stand=G.mesh()
for tier=0,3 do
    local height=(tier+1)*0.65;local z=tier*1.7
    G.append(S.stand,G.box(16,height,1.7,12,11,5),0,height/2,z+0.85)
    G.quad(S.stand,{-7.6,height+0.015,z+0.55},{-7.6,height+0.015,z+0.85},{7.6,height+0.015,z+0.85},{7.6,height+0.015,z+0.55},8)
end
-- Checkered end panels, geometry rather than texture bitmaps.
for _,side in ipairs({-1,1}) do for row=0,1 do for col=0,1 do
    local x=side*8.015;local z=col*1.6+2.8;local y=row*1.0
    local q={{x,y,z},{x,y+1,z},{x,y+1,z+1.6},{x,y,z+1.6}}
    if side<0 then q={q[4],q[3],q[2],q[1]} end
    G.quad(S.stand,q[1],q[2],q[3],q[4],(row+col)%2==0 and 9 or 0)
end end end
G.quad(S.stand,{-8,0,6.85},{8,0,6.85},{8,3.3,6.85},{-8,3.3,6.85},11)
G.quad(S.stand,{-8,3.3,6.85},{8,3.3,6.85},{8,0,6.85},{-8,0,6.85},12)
S.tirePile=G.mesh()
local function tire(x,y,z)
    local m=G.mesh()
    local ring={}
    for i=0,5 do ring[i+1]={math.cos(i*math.pi/3)*0.52,math.sin(i*math.pi/3)*0.52} end
    for i=1,6 do
        local a,b=ring[i],ring[i%6+1]
        G.quad(m,{a[1],0,a[2]},{a[1],0.46,a[2]},{b[1],0.46,b[2]},{b[1],0,b[2]},0)
    end
    for _,layer in ipairs({{1,0.46,10},{0.48,0.465,0}}) do
        local n=#m.v/3
        for _,p in ipairs(ring) do m.v[#m.v+1]=p[1]*layer[1];m.v[#m.v+1]=layer[2];m.v[#m.v+1]=p[2]*layer[1] end
        for i=2,5 do for _,v in ipairs({n+1,n+i+1,n+i,layer[3]}) do m.f[#m.f+1]=v end end
    end
    G.append(S.tirePile,m,x,y,z)
end
tire(-0.55,0,0);tire(0.55,0,0);tire(0,0.46,0)
function S.populate(T)
    T.stadium={};T.stadiumTrees={}
    T.field={x=0,y=0,z=0,mesh=G.mesh()}
    G.quad(T.field.mesh,{-55,-0.05,-46},{-55,-0.05,46},{55,-0.05,46},{55,-0.05,-46},14)
    -- Low continuous white barriers, omitted at the actual flat crossing.
    for i,p in ipairs(T.parts) do
        if i%2==0 and (T.id~=2 or p.x*p.x+p.z*p.z>110 or p.raised) then
            local m=G.mesh()
            for _,side in ipairs({-1,1}) do
                local w=(T.halfWidth+0.65)*side
                local ax,az=p.a.x+p.a.nx*w,p.a.z+p.a.nz*w
                local bx,bz=p.b.x+p.b.nx*w,p.b.z+p.b.nz*w
                G.quad(m,{ax-p.x,p.a.y+0.16,az-p.z},{ax-p.x,p.a.y+0.65,az-p.z},{bx-p.x,p.b.y+0.65,bz-p.z},{bx-p.x,p.b.y+0.16,bz-p.z},9)
                G.quad(m,{bx-p.x,p.b.y+0.16,bz-p.z},{bx-p.x,p.b.y+0.65,bz-p.z},{ax-p.x,p.a.y+0.65,az-p.z},{ax-p.x,p.a.y+0.16,az-p.z},12)
            end
            T.stadium[#T.stadium+1]={x=p.x,y=0,z=p.z,radius=p.radius+1,mesh=m,kind="barrier"}
        end
    end
    -- Two grandstands on safe, opposite outward edges.
    local stands=0
    for _,fraction in ipairs({0.02,0.52,0.20,0.70,0.35,0.85}) do
        local x,z,yaw=T.sample(T.segments*fraction)
        local tx,tz=x+math.cos(yaw)*15,z-math.sin(yaw)*15
        local _,d=T.locate(tx,tz)
        if d>100 and stands<2 then
            T.stadium[#T.stadium+1]={x=tx,y=0,z=tz,yaw=yaw+math.pi/2,mesh=S.stand,radius=12,kind="grandstand"}
            stands=stands+1
        end
    end
    -- Additional clustered foliage; all crowns reuse one mesh.
    for _,tree in ipairs(T.trees) do
        for _,offset in ipairs({{-2.6,2.1},{2.6,1.8}}) do
            local x,z=tree.x+offset[1],tree.z+offset[2]
            local _,d=T.locate(x,z)
            if d>36 then T.stadiumTrees[#T.stadiumTrees+1]={x=x,y=0,z=z,mesh=S.tree,radius=5} end
        end
    end
    -- Small wooded islands at the sides, rejected if close to the driving surface.
    for _,seed in ipairs({{38,28},{38,-28},{-40,8},{-42,-8}}) do
        for _,o in ipairs({{-2,0},{1,2},{2,-2}}) do
            local x,z=seed[1]+o[1],seed[2]+o[2]
            local _,d=T.locate(x,z)
            local clear=d>49
            for _,obj in ipairs(T.stadium) do if obj.kind=="grandstand" and (obj.x-x)^2+(obj.z-z)^2<169 then clear=false end end
            if clear then T.stadiumTrees[#T.stadiumTrees+1]={x=x,y=0,z=z,mesh=S.tree,radius=5} end
        end
    end
    local piles=0
    for _,fraction in ipairs({0.12,0.37,0.62,0.87,0.25,0.75}) do
        local x,z,yaw=T.sample(T.segments*fraction)
        x,z=x+math.cos(yaw)*7.8,z-math.sin(yaw)*7.8
        local _,d=T.locate(x,z)
        if d>36 and piles<4 then
            T.stadium[#T.stadium+1]={x=x,y=0,z=z,yaw=yaw,mesh=S.tirePile,radius=2,kind="tire pile"};piles=piles+1
        end
    end
    -- Concrete perimeter edging of the stadium field; no projected shadows.
    for _,edge in ipairs({{0,-46,112,2},{0,46,112,2},{-55,0,2,94},{55,0,2,94}}) do
        T.stadium[#T.stadium+1]={x=edge[1],y=-0.2,z=edge[2],mesh=G.box(edge[3],0.5,edge[4],12,11,9),radius=60,kind="perimeter"}
    end
    if T.id==2 then
        for _,progress in ipairs({T.segments/2-T.startOffset-1.5,T.segments/2-T.startOffset+1.5}) do
            local x,z,yaw=T.sample(progress);local height=T.height(progress)-0.28
            for _,side in ipairs({-1,1}) do
                T.stadium[#T.stadium+1]={x=x+math.cos(yaw)*3*side,y=height/2,z=z-math.sin(yaw)*3*side,
                    mesh=G.box(0.5,height,0.7,12,11,5),radius=3,kind="bridge pier"}
            end
        end
    end
end
return S
