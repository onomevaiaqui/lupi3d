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
local level=require "level"
assert(#level.obstacles>0 and #level.targets==6)
assert(level.free(6.6,0,10.75,0.18,1.5),"player must fit below the overhead beam")
assert(not level.free(6.6,0.8,10.75,0.18,1.5),"raised body must collide with the overhead beam")
local sloped=0
local rock=require "rock"
for i=1,#rock.f,4 do
    local a,b,c=(rock.f[i]-1)*3+1,(rock.f[i+1]-1)*3+1,(rock.f[i+2]-1)*3+1
    local ux,uy,uz=rock.v[b]-rock.v[a],rock.v[b+1]-rock.v[a+1],rock.v[b+2]-rock.v[a+2]
    local vx,vy,vz=rock.v[c]-rock.v[a],rock.v[c+1]-rock.v[a+1],rock.v[c+2]-rock.v[a+2]
    local nx,ny,nz=uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx
    if math.abs(nx)>0.00001 and math.abs(ny)>0.00001 and math.abs(nz)>0.00001 then sloped=sloped+1 end
end
assert(sloped>0,"imported rock must contain sloped XYZ triangles")
local weapon=require "gun";local minZ,maxZ=math.huge,-math.huge
for i=3,#weapon.v,3 do minZ=math.min(minZ,weapon.v[i]);maxZ=math.max(maxZ,weapon.v[i]) end
assert(maxZ-minZ>0.5 and #weapon.f/4>=40,"weapon must have 3D volume")
points={};R.begin(camera);R.submit({x=0,y=0,z=0,mesh=weapon.flash},true);R.flush()
assert(#points>0,"3D muzzle flash must render triangles")
print("PASS: perspective depth, XYZ elevation, camera pitch, near-plane clipping and volumetric 3D weapon")
