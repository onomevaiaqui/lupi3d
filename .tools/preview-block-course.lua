-- Capture the actual game renderer at its native 480x270 resolution.
local file
local palette={}
local function emit(k,...) file:write(k,',',table.concat({...},','),'\n') end
ui=setmetatable({palset=function(i,c)palette[i]=c end,
 cls=function(c)emit('rect',0,0,480,270,c)end,
 rectfill=function(...)emit('rect',...)end,trisfill=function(...)emit('tri',...)end,
 print=function(s,x,y,c)emit('text',x,y,c,s)end},
 {__index=function()return function()end end})
local open=io.open
io=nil
require 'game'
Game.detail=true
for view,progress in ipairs({0,8,20,44,68}) do
 math.randomseed(91);Game.startRace(8)
 local r=Game.race;r.countdown=0;r.time=4;r.throttle=true
 for j,c in ipairs(r.cars) do
  local lane=((j-1)%3-1)*2.4
  c.x,c.z,c.yaw,c.y=r.track.sampleLane(progress+(j-1)*0.4,lane)
  c.speed=12
 end
 if arg[1]=='hud' then
  require('combat').collect(r.player,'shot');require('combat').collect(r.player,'mine')
  if view==4 then require('combat').select(r.player) end
 end
 file=assert(open('.tools/block-course-'..view..'.csv','w'))
 Game.draw();file:close()
 assert(Game.dropped==0,'Triangle pool overflow')
 print('view '..view..': '..Game.triangles..' rasterized triangles')
end
file=assert(open('.tools/palette.csv','w'))
for i=0,#require('colors').palette-1 do file:write(i,',',palette[i],'\n') end
file:close()
