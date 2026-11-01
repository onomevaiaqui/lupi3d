local G=require "geometry"
local names={"VALE OVAL","CRUZAMENTO 8","SERRA VERDE"}
local function new(id)
assert(id>=1 and id<=3)
local T={id=id,name=names[id],segments=id==1 and 40 or 48,halfWidth=3.6,parts={},trees={}}
local tau=2*math.pi
local function p(t)
    if id==1 then return 20*math.sin(t),32*math.cos(t) end
    if id==2 then return 30*math.sin(t),44*math.sin(t)*math.cos(t) end
    return 24*math.sin(t)+5*math.sin(3*t),30*math.cos(t)
end
local points={}
for i=0,T.segments do
    local t=i*tau/T.segments;local x,z=p(t)
    local xa,za=p(t-0.001);local xb,zb=p(t+0.001)
    local dx,dz=xb-xa,zb-za;local n=math.sqrt(dx*dx+dz*dz)
    points[i]={x=x,z=z,nx=dz/n,nz=-dx/n}
end
T.length=0
for i=0,T.segments-1 do
    local a,b=points[i],points[i+1];local dx,dz=b.x-a.x,b.z-a.z
    local s={x=(a.x+b.x)/2,y=0,z=(a.z+b.z)/2,mesh=G.mesh(),a=a,b=b,dx=dx,dz=dz,len2=dx*dx+dz*dz}
    s.length=math.sqrt(s.len2);T.length=T.length+s.length
    s.radius=s.length/2+T.halfWidth+0.35
    local function edge(v,w) return {v.x+v.nx*w-s.x,0,v.z+v.nz*w-s.z} end
    -- Winding follows +Y regardless of the turn direction.
    G.quad(s.mesh,edge(a,-T.halfWidth),edge(b,-T.halfWidth),edge(b,T.halfWidth),edge(a,T.halfWidth),10)
    s.trim={x=s.x,y=0,z=s.z,mesh=G.mesh(),radius=s.radius}
    for _,side in ipairs({-1,1}) do
        local w=T.halfWidth*side;local o=(T.halfWidth+0.28)*side
        local q={edge(a,w),edge(a,o),edge(b,o),edge(b,w)}
        if side>0 then q={q[4],q[3],q[2],q[1]} end
        if id~=2 or s.x*s.x+s.z*s.z>64 then G.quad(s.trim.mesh,q[1],q[2],q[3],q[4],i%2==0 and 7 or 9) end
    end
    T.parts[i+1]=s
end
function T.sample(progress)
    local f=progress%T.segments;local i=math.floor(f);local u=f-i;local s=T.parts[i+1]
    return s.a.x+s.dx*u,s.a.z+s.dz*u,math.atan(s.dx,s.dz),s.length
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
    if not hint or best>144 then for i=0,T.segments-1 do check(i) end end
    return progress%T.segments,best
end
T.finish={x=points[0].x,y=0.018,z=points[0].z,mesh=G.mesh(),radius=4}
local a=points[0];local dx,dz=-a.nz,a.nx
for i=0,7 do
    local w=-3.2+i*0.8
    local function v(u,l) return {a.nx*u+dx*l,0,a.nz*u+dz*l} end
    G.quad(T.finish.mesh,v(w,0.4),v(w+0.8,0.4),v(w+0.8,-0.4),v(w,-0.4),i%2==0 and 9 or 0)
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
    local tx,tz=x+math.cos(yaw)*8,z-math.sin(yaw)*8
    local _,dist=T.locate(tx,tz)
    if dist>36 then T.trees[#T.trees+1]={x=tx,y=0,z=tz,mesh=tree,radius=4} end
end
return T
end
return {new=new,names=names}
