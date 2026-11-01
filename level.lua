local G=require "geometry"
local M={spawn={x=6.5,z=2.5,yaw=0},objects={},obstacles={},rayBoxes={},targets={}}
local topColors={[5]=12,[6]=5,[13]=8,[11]=12,[12]=9}
local function box(name,x,y,z,w,h,d,color,solid)
    -- Baked material lighting: bright tops, shaded sides; no per-frame lights.
    local obj={name=name,x=x,y=y,z=z,mesh=G.box(w,h,d,color,color+16,topColors[color] or color)}
    M.objects[#M.objects+1]=obj
    local b={name=name,minx=x-w/2,maxx=x+w/2,miny=y-h/2,maxy=y+h/2,minz=z-d/2,maxz=z+d/2}
    M.rayBoxes[#M.rayBoxes+1]=b
    if solid then M.obstacles[#M.obstacles+1]=b end
end
M.floor={x=0,y=0,z=0,mesh=G.mesh()}
for x=0,2 do for z=0,2 do
    local a,b=x*14/3,z*14/3
    G.quad(M.floor.mesh,{a,0,b},{a,0,b+14/3},{a+14/3,0,b+14/3},{a+14/3,0,b},2+(x+z)%2)
end end
box("west",0.5,1.5,7,1,3,14,5,true)
box("east",13.5,1.5,7,1,3,14,6,true)
box("north",7,1.5,0.5,12,3,1,5,true)
box("south",7,1.5,13.5,12,3,1,5,true)
box("left divider",3.75,1.1,5.5,1.5,2.2,3,13,true)
box("right divider",10.25,1.1,5.5,1.5,2.2,3,6,true)
box("low cover",7,0.8,9,2,1.6,2,11,true)
box("raised platform",9.7,0.275,8.25,2,0.55,1.5,12,true)
box("arch left",5,1.05,10.75,0.4,2.1,0.5,11,true)
box("arch right",8.2,1.05,10.75,0.4,2.1,0.5,11,true)
box("overhead beam",6.6,2.25,10.75,3.6,0.3,0.5,12,true)
local rock={name="KayKit rock",x=2.1,y=0,z=9,mesh=require "rock"}
M.objects[#M.objects+1]=rock
local rb={name="rock",minx=math.huge,miny=math.huge,minz=math.huge,maxx=-math.huge,maxy=-math.huge,maxz=-math.huge}
for i=1,#rock.mesh.v,3 do
    local x,y,z=rock.mesh.v[i]+rock.x,rock.mesh.v[i+1],rock.mesh.v[i+2]+rock.z
    rb.minx,rb.maxx=math.min(rb.minx,x),math.max(rb.maxx,x)
    rb.miny,rb.maxy=math.min(rb.miny,y),math.max(rb.maxy,y)
    rb.minz,rb.maxz=math.min(rb.minz,z),math.max(rb.maxz,z)
end
M.obstacles[#M.obstacles+1]=rb;M.rayBoxes[#M.rayBoxes+1]=rb
local targetMesh=G.box(0.84,0.9,0.5,7,23,8)
-- Fixed front-face inlays, actual XYZ polygons: they do not turn toward the camera.
G.quad(targetMesh,{-0.30,-0.31,-0.251},{-0.30,0.31,-0.251},{0.30,0.31,-0.251},{0.30,-0.31,-0.251},9)
G.quad(targetMesh,{0,-0.22,-0.252},{-0.21,0,-0.252},{0,0.22,-0.252},{0.21,0,-0.252},8)
local points={{6.5,1.05,6.5},{1.7,1.05,5.5},{11.8,2.0,5.5},{3.5,1.05,10.8},{10.5,2.0,10.8},{6.5,2.0,12}}
for i,p in ipairs(points) do
    local t={id=i,x=p[1],y=p[2],z=p[3],alive=true,mesh=targetMesh,bounds={}}
    M.targets[i]=t
    local height=p[2]-0.45
    box("target stand",p[1],height/2,p[3],0.12,height,0.12,11,false)
end
function M.targetBox(t)
    local b=t.bounds
    b.minx,b.maxx=t.x-0.42,t.x+0.42;b.miny,b.maxy=t.y-0.45,t.y+0.45;b.minz,b.maxz=t.z-0.25,t.z+0.25
    return b
end
for _,t in ipairs(M.targets) do local b=M.targetBox(t);b.target=t;M.obstacles[#M.obstacles+1]=b end
local function active(b)
    if b.target then M.targetBox(b.target);return b.target.alive end
    return true
end
function M.overlap(b,x,z,r)
    local dx=x-math.max(b.minx,math.min(x,b.maxx))
    local dz=z-math.max(b.minz,math.min(z,b.maxz))
    return dx*dx+dz*dz<r*r
end
function M.free(x,y,z,r,h)
    if x<1+r or x>13-r or z<1+r or z>13-r then return false end
    for _,b in ipairs(M.obstacles) do
        if active(b) and y<b.maxy-0.00001 and y+h>b.miny+0.00001 and M.overlap(b,x,z,r) then return false end
    end
    return true
end
function M.ray(x,y,z,dx,dy,dz)
    local nearest=(dy< -1e-8 and y>0) and -y/dy or 1000
    for _,b in ipairs(M.rayBoxes) do
        local distance=G.rayBox(b,x,y,z,dx,dy,dz,nearest)
        if distance and distance<nearest then nearest=distance end
    end
    return nearest
end
function M.vertical(x,z,y,vy,dt,r,h,gravity)
    local nextY=y+vy*dt-0.5*gravity*dt*dt
    local nextVy=vy-gravity*dt
    if nextY>y then
        for _,b in ipairs(M.obstacles) do
            if active(b) and y+h<=b.miny+0.00001 and nextY+h>b.miny and M.overlap(b,x,z,r) then
                nextY=math.min(nextY,b.miny-h);nextVy=0
            end
        end
    else
        local support=0
        for _,b in ipairs(M.obstacles) do
            if active(b) and y>=b.maxy-0.00001 and nextY<=b.maxy and M.overlap(b,x,z,r) then support=math.max(support,b.maxy) end
        end
        if nextY<=support then return support,0,true end
    end
    return nextY,nextVy,false
end
return M
