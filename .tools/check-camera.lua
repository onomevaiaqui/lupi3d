-- Reproduce sustained L/R input from the initial angle, including every wrap.
package.path="./?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_F,BTN_G,BTN_Q,BTN_E,BTN_Z=4,2,1,3,9,11,5,8,7
local keys,triangles={},0
ui={btn=function(k) return keys[k] or false end,palset=function() end,camera=function() end,
clip=function() end,cls=function() end,rectfill=function() end,print=function() end,
trisfill=function(a,b,c,d,e,f)
    for _,v in ipairs({a,b,c,d,e,f}) do assert(v==v and math.abs(v)<1000,"invalid camera projection") end
    assert((c-a)*(f-b)-(d-b)*(e-a)>0,"invalid integer raster triangle")
    triangles=triangles+1
end}
require "game"
for mode=0,5 do
    for _,button in ipairs({BTN_Q,BTN_E}) do
        Game.x,Game.z,Game.y,Game.vy,Game.yaw,Game.phase=0,0,0,0,0,0
        Game.profile_mode=mode
        keys={[button]=true}
        for _=1,600 do
            Game.step(1/30); Game.draw()
            assert(Game.yaw>=0 and Game.yaw<math.pi*2,"invalid wrapped yaw")
            assert(Game.profile_mode==mode,"camera button changed the profile")
            assert(Game.dropped==0,"camera exhausts triangle pool")
        end
        keys={}
        local yaw=Game.yaw
        for _=1,10 do Game.step(1/30);Game.draw() end
        assert(Game.yaw==yaw,"camera continues after release")
    end
end
-- Each direction must also work while walking and jumping near the platform.
for _,button in ipairs({BTN_Q,BTN_E}) do
    Game.x,Game.z,Game.y,Game.vy,Game.yaw,Game.phase=0,0,0,0,0,0
    Game.grounded=true;Game.profile_mode=0
    keys={[button]=true,[UP]=true,[BTN_Z]=true}
    for _=1,120 do Game.step(1/30);Game.draw();assert(Game.dropped==0) end
    keys={};Game.step(1/30)
end
print("PASS: 20-second L/R holds from yaw zero in all six profiles, wraps, release and finite projection")
