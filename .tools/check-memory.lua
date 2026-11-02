-- Fresh process, no retained test races or captured CSV commands.
LEFT,RIGHT,UP,DOWN,BTN_F,BTN_G,BTN_Q,BTN_E,BTN_Z,BTN_X=4,2,1,3,9,11,5,8,7,6
local cfg=require "config";cfg.save_dir=".tools/"
ui={btn=function() return false end,palset=function() end,camera=function() end,clip=function() end,cls=function() end,rectfill=function() end,print=function() end,trisfill=function() end}
require "game"
for id=1,3 do
    Game.startRace(id)
    for i=0,95 do
        local r=Game.race;local p=r.player;p.progress=i*r.track.segments/96
        p.x,p.z,p.yaw=r.track.sample(p.progress);p.y=r.track.height(p.progress)
        Game.draw();assert(Game.dropped==0)
    end
    Game.overview=true;Game.draw();assert(Game.dropped==0);local overviewHigh=Game.triangles
    Game.detail=false;Game.draw();assert(Game.dropped==0);local overviewLow=Game.triangles
    Game.detail=true;Game.overview=false
    collectgarbage("collect")
    local heap=collectgarbage("count")
    assert(heap<2048,"Lua scene alone must leave RAM headroom for firmware")
    print(string.format("Track %d: retained Lua %.1f KiB after 96 views; whole-stadium %d/%d high/low triangles (not complete console RAM)",id,heap,overviewHigh,overviewLow))
end
