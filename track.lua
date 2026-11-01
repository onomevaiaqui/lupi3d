local G=require "geometry"
local T={a=18,b=28,inner=0.83,outer=1.17,segments=24}
T.ground={x=0,y=0,z=0,mesh=G.mesh()}
G.quad(T.ground.mesh,{-60,-0.04,-65},{-60,-0.04,65},{60,-0.04,65},{60,-0.04,-65},14)
T.road={x=0,y=0,z=0,mesh=G.mesh()}
local function point(angle,r,y) return {math.sin(angle)*T.a*r,y,math.cos(angle)*T.b*r} end
for i=0,T.segments-1 do
    local a,b=i*2*math.pi/T.segments,(i+1)*2*math.pi/T.segments
    G.quad(T.road.mesh,point(a,T.inner,0),point(a,T.outer,0),point(b,T.outer,0),point(b,T.inner,0),10)
    -- Red/white curbs are real horizontal XYZ polygons.
    G.quad(T.road.mesh,point(a,T.inner-0.025,0.006),point(a,T.inner,0.006),point(b,T.inner,0.006),point(b,T.inner-0.025,0.006),i%2==0 and 7 or 9)
    G.quad(T.road.mesh,point(a,T.outer,0.006),point(a,T.outer+0.025,0.006),point(b,T.outer+0.025,0.006),point(b,T.outer,0.006),i%2==0 and 7 or 9)
end
T.finish={x=0,y=0,z=0,mesh=G.mesh()}
for row=0,1 do for col=0,7 do
    local x=-0.55+row*0.55;local z=-33+col*1.25
    G.quad(T.finish.mesh,{x,0.012,z},{x,0.012,z+1.25},{x+0.55,0.012,z+1.25},{x+0.55,0.012,z},(row+col)%2==0 and 9 or 0)
end end
function T.radius(x,z) return math.sqrt((x/T.a)^2+(z/T.b)^2) end
function T.phase(x,z) return (math.pi-math.atan(x/T.a,z/T.b))%(2*math.pi) end
return T
