package.path="./?.lua;"..package.path
ui={btn=function() return false end,palset=function() end,camera=function() end,
clip=function() end,cls=function() end,rectfill=function() end,print=function() end}
local own=require("colors").palette
package.loaded.colors=nil
package.preload.palette=function() Palette=own;return Palette end
package.preload.sprites=function() Sprites={img={gun={path="img/gun",width=72,height=96}}};return Sprites end
local calls,area=0,0
ui.rectfill=function(a,b,c,d) calls=calls+1;area=area+(c-a)*(d-b) end
ui.spr=function() calls=calls+1 end
ui.trisfill=function() error("FPS renderer must not submit triangles") end
require "main"
assert(Game.native_weapon)
local maxCalls,maxArea=0,0
collectgarbage("collect");local start=os.clock()
for _,p in ipairs({{6.5,2.5},{1.5,2.5},{11.5,2.5},{4.5,10.5},{10.5,10.5}}) do
    Game.x,Game.z=p[1],p[2]
    for _,height in ipairs({0,0.97}) do
        Game.y=height
        for degrees=-180,175,5 do
            Game.yaw=degrees*math.pi/180;calls,area=0,0;Game.draw()
            maxCalls=math.max(maxCalls,calls);maxArea=math.max(maxArea,area)
        end
    end
end
local ms=(os.clock()-start)/720*1000
collectgarbage("collect")
print(string.format("720 native-sprite views; zero triangles; max draw calls %d; max rectangle area %.0f px (excluding clear/sprite); Lua %.3f ms/frame; heap %.1f KiB. Not hardware timing.",maxCalls,maxArea,ms,collectgarbage("count")))
