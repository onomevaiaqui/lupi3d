package.path="./?.lua;"..package.path
local points={}
ui={trisfill=function(a,b,c,d,e,f,color)
    assert((c-a)*(f-b)-(d-b)*(e-a)>0)
    assert(a>=0 and a<=479 and c>=0 and c<=479 and e>=0 and e<=479)
    assert(b>=20 and b<=227 and d>=20 and d<=227 and f>=20 and f<=227)
    points[#points+1]={a,b,c,d,e,f}
end}
local G=require "geometry"
local R=require "renderer"
local camera={x=0,y=0,z=0,yaw=0,pitch=0}
local obj={x=0,y=1.05,z=4,mesh=G.box(1,1,1,7,23,8)}
local function bounds()
    points={};R.begin(camera);R.submit(obj);R.flush()
    local xmin,xmax,ymin,ymax=480,0,270,0
    for _,t in ipairs(points) do for i=1,6,2 do xmin=math.min(xmin,t[i]);xmax=math.max(xmax,t[i]);ymin=math.min(ymin,t[i+1]);ymax=math.max(ymax,t[i+1]) end end
    return xmax-xmin,ymin,ymax
end
local near=bounds();obj.z=8;local far=bounds()
assert(near>far*1.8 and near<far*2.4,"XYZ depth must change projected size")
local _,baseY=bounds();obj.y=1.7;local _,raisedY=bounds()
assert(raisedY<baseY,"XYZ height must change projected position")
camera.pitch=0.15;local _,pitchedY=bounds();assert(pitchedY>raisedY,"pitch must rotate the 3D camera")
camera.pitch=0;obj.y=1.05
for _,z in ipairs({-1,0,0.1,0.5,1,4}) do obj.z=z;bounds();assert(R.dropped==0) end
obj.z=4;obj.y=0.4;obj.yaw=0.7;bounds();assert(#points>0)
local car=require "car"
assert(#car.v>0 and #car.f>0)
print("PASS: perspective, XYZ elevation, camera pitch, near-plane clipping and object yaw")
-- High-angle culling must match unbounded projection for nearby visible boxes.
camera={x=-12,y=18,z=-14,yaw=math.atan(12,14),pitch=-math.atan(18/math.sqrt(340))}
for x=-8,8,8 do for z=-8,8,8 do
    obj.x,obj.y,obj.z,obj.yaw=x,0.5,z,0
    obj.radius=nil;points={};R.begin(camera);R.submit(obj);R.flush();local expected=#points
    obj.radius=1;points={};R.begin(camera);R.submit(obj);R.flush()
    assert(#points==expected,"steep-camera culling discarded visible XYZ geometry")
end end
print("PASS: high-angle camera frustum retains visible objects")