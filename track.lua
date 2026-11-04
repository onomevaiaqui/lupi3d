local G=require "geometry"
local names={"VALE OVAL","CRUZAMENTO 8","SERRA VERDE","PEDREIRA","LAGOA","VIADUTO NORTE","ESTRADA REAL","VIADUTO SUL","AUTODROMO"}
-- Ground, alternating asphalt shades and curb accent from the 32-color palette.
local themes={
    {14,2,3,7},{30,3,4,8},{14,2,3,15},
    {13,2,3,8},{6,2,3,12},{29,3,4,8},
    {15,2,3,13},{30,2,3,7},{27,2,3,7}
}
local function new(id)
assert(id>=1 and id<=#names)
local T={id=id,name=names[id],segments=({40,48,48,36,48,64,64,72,80})[id],bridge=id==6 or id==8,quarry=id==4,halfWidth=5.4,parts={},trees={}}
local scale=({1.32,1.20,1.32,1.65,1.30,1.17,1.16,1.13,1.10})[id]
T.bound=math.ceil(({55,55,55,55,60,70,78,85,95})[id]*scale)
T.theme=themes[id]
local tau=2*math.pi
local function p(t)
    if id==1 then return 20*math.sin(t),32*math.cos(t) end
    if id==2 then return 30*math.sin(t),44*math.sin(t)*math.cos(t) end
    if id==4 then return 16*math.sin(t)+3*math.sin(2*t),23*math.cos(t) end
    if id==5 then return 28*math.sin(t)+5*math.cos(2*t),27*math.cos(t)+3*math.sin(2*t) end
    if id==6 then return 38*math.sin(t),56*math.sin(t)*math.cos(t) end
    if id==7 then return 34*math.sin(t)+9*math.sin(3*t),51*math.cos(t) end
    if id==8 then return 62*math.sin(t)*math.cos(t)+10*math.sin(t),47*math.sin(t) end
    if id==9 then return 48*math.sin(t)+8*math.sin(3*t),68*math.cos(t)+9*math.cos(2*t) end
    return 24*math.sin(t)+5*math.sin(3*t),30*math.cos(t)
end
local points={}
for i=0,T.segments do
    local t=((i+(T.bridge and T.segments/8 or 0))%T.segments)*tau/T.segments;local x,z=p(t)
    local xa,za=p(t-0.001);local xb,zb=p(t+0.001)
    local dx,dz=xb-xa,zb-za;local n=math.sqrt(dx*dx+dz*dz)
    local y=T.bridge and 5*math.max(0,1-math.abs(t-math.pi)/0.8) or 0
    points[i]={x=x*scale,y=y,z=z*scale,nx=dz/n,nz=-dx/n}
end
-- Choose a flat, nearly straight stretch long enough for the starting grid.
local start,best=0,math.huge
local span=3
for i=0,T.segments-1 do
    local a,b=points[(i-span)%T.segments],points[(i+span)%T.segments]
    local dx,dz=b.x-a.x,b.z-a.z
    local length=math.sqrt(dx*dx+dz*dz)
    if length>=22 then
        local deviation,flat=0,true
        for j=-span,span do
            local p=points[(i+j)%T.segments]
            flat=flat and p.y==0
            deviation=math.max(deviation,math.abs((p.x-a.x)*dz-(p.z-a.z)*dx)/length)
        end
        local center=points[i]
        local awayFromCrossing=(id~=2 and not T.bridge) or center.x^2+center.z^2>18^2
        if flat and awayFromCrossing and deviation<best then start,best=i,deviation end
    end
end
assert(best<math.huge,"no flat starting straight")
local ordered={}
for i=0,T.segments-1 do ordered[i]=points[(i+start)%T.segments] end
points=ordered
local a,b=points[T.segments-span],points[span]
local dx,dz=b.x-a.x,b.z-a.z
local length=math.sqrt(dx*dx+dz*dz)
for j=-span+1,span-1 do
    local u=(j+span)/(2*span)
    points[j%T.segments]={x=a.x+dx*u,y=0,z=a.z+dz*u,nx=dz/length,nz=-dx/length}
end
points[T.segments]=points[0]
T.length=0
for i=0,T.segments-1 do
    local a,b=points[i],points[i+1];local dx,dz=b.x-a.x,b.z-a.z
    local s={x=(a.x+b.x)/2,y=0,z=(a.z+b.z)/2,mesh=G.mesh(),a=a,b=b,dx=dx,dz=dz,len2=dx*dx+dz*dz}
    s.length=math.sqrt(s.len2);T.length=T.length+s.length
    s.radius=s.length/2+T.halfWidth+0.35
    s.raised=a.y>0 or b.y>0
    local function edge(v,w) return {v.x+v.nx*w-s.x,v.y,v.z+v.nz*w-s.z} end
    -- Winding follows +Y regardless of the turn direction.
    G.quad(s.mesh,edge(a,-T.halfWidth),edge(b,-T.halfWidth),edge(b,T.halfWidth),edge(a,T.halfWidth),T.theme[i%9<3 and 3 or 2])
    if s.raised then
        for _,side in ipairs({-1,1}) do
            local u,v=edge(a,T.halfWidth*side),edge(b,T.halfWidth*side)
            local lowU,lowV={u[1],u[2]-0.45,u[3]},{v[1],v[2]-0.45,v[3]}
            if side<0 then G.quad(s.mesh,v,u,lowU,lowV,11)
            else G.quad(s.mesh,u,v,lowV,lowU,11) end
        end
    end
    s.trim={x=s.x,y=0,z=s.z,mesh=G.mesh(),radius=s.radius}
    for _,side in ipairs({-1,1}) do
        local w=T.halfWidth*side;local o=(T.halfWidth+0.28)*side
        local q={edge(a,w),edge(a,o),edge(b,o),edge(b,w)}
        if side>0 then q={q[4],q[3],q[2],q[1]} end
        if id~=2 or s.x*s.x+s.z*s.z>100 then G.quad(s.trim.mesh,q[1],q[2],q[3],q[4],i%2==0 and T.theme[4] or 9) end
    end
    T.parts[i+1]=s
end
function T.sample(progress)
    local f=progress%T.segments;local i=math.floor(f);local u=f-i;local s=T.parts[i+1]
    return s.a.x+s.dx*u,s.a.z+s.dz*u,math.atan(s.dx,s.dz),s.length,s.a.y+(s.b.y-s.a.y)*u
end
function T.locate(x,z,hint)
    local best,progress=math.huge,0
    local function check(i)
        local s=T.parts[i%T.segments+1]
        local u=math.max(0,math.min(1,((x-s.a.x)*s.dx+(z-s.a.z)*s.dz)/s.len2))
        local dx,dz=x-s.a.x-s.dx*u,z-s.a.z-s.dz*u
        local d=dx*dx+dz*dz
        if d<best then best,progress=d,(i%T.segments)+u end
    end
    if hint then for i=math.floor(hint)-4,math.floor(hint)+4 do check(i) end end
    if not hint or (best>144 and not T.bridge) then for i=0,T.segments-1 do check(i) end end
    return progress%T.segments,best
end
T.finish={x=points[0].x,y=0.018,z=points[0].z,mesh=G.mesh(),radius=T.halfWidth+1}
local a=points[0];local dx,dz=-a.nz,a.nx
for i=0,7 do
    local tile=T.halfWidth/4
    local w=-T.halfWidth+i*tile
    local function v(u,l) return {a.nx*u+dx*l,0,a.nz*u+dz*l} end
    G.quad(T.finish.mesh,v(w,0.4),v(w+tile,0.4),v(w+tile,-0.4),v(w,-0.4),i%2==0 and 9 or 0)
end
-- Shared 8-triangle tree: solid pyramid canopy plus two trunk faces.
local tree=G.mesh()
local v={{-1,1,-1},{1,1,-1},{1,1,1},{-1,1,1},{0,3.7,0}}
for _,q in ipairs(v) do for _,n in ipairs(q) do tree.v[#tree.v+1]=n end end
tree.f={1,5,2,14,2,5,3,30,3,5,4,14,4,5,1,30}
G.quad(tree,{-0.16,0,-0.16},{-0.16,1.4,-0.16},{0.16,1.4,-0.16},{0.16,0,-0.16},13)
G.quad(tree,{0.16,0,-0.16},{0.16,1.4,-0.16},{0.16,1.4,0.16},{0.16,0,0.16},29)
for i=1,6 do
    local progress=(i-0.3)*T.segments/6
    local x,z,yaw=T.sample(progress)
    local tx,tz=x+math.cos(yaw)*9,z-math.sin(yaw)*9
    local _,dist=T.locate(tx,tz)
    if dist>(T.halfWidth+2)^2 then T.trees[#T.trees+1]={x=tx,y=0,z=tz,mesh=tree,radius=4} end
end
require("scenery").populate(T)
return T
end
return {new=new,names=names}
