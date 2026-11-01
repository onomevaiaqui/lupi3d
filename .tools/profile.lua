package.path="./?.lua;"..package.path
local triangles,area=0,0
ui={btn=function() return false end,palset=function() end,camera=function() end,
clip=function() end,cls=function() end,rectfill=function() end,print=function() end,
spr=function() error("not a 3D weapon") end,
trisfill=function(a,b,c,d,e,f) triangles=triangles+1;area=area+math.abs((c-a)*(f-b)-(d-b)*(e-a))/2 end}
require "main"
local maxTriangles,maxArea=0,0
collectgarbage("collect");local start=os.clock()
for _,p in ipairs({{6.5,2.5},{1.5,2.5},{11.5,2.5},{3.5,10.8},{10.5,10.8}}) do
    Game.x,Game.z=p[1],p[2]
    for _,height in ipairs({0,0.97}) do
        Game.y=height
        for degrees=-180,175,5 do
            Game.yaw=degrees*math.pi/180;triangles,area=0,0;Game.draw()
            maxTriangles=math.max(maxTriangles,triangles);maxArea=math.max(maxArea,area)
        end
    end
end
local ms=(os.clock()-start)/720*1000;collectgarbage("collect")
print(string.format("720 genuine XYZ 3D views; max triangles %d; max projected area %.0f px; Lua %.3f ms/frame; heap %.1f KiB. Not hardware timing.",maxTriangles,maxArea,ms,collectgarbage("count")))
