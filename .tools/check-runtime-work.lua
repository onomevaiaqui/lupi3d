local cfg=require 'config';cfg.save_dir='.build/no-runtime-saves/'
local tracks=require 'track'
local t=tracks.new(8)
collectgarbage('collect');collectgarbage('stop')
local before=collectgarbage('count')
for i=1,10000 do t.locate(i%40-20,i%60-30,i%t.segments,0)end
local growth=collectgarbage('count')-before
collectgarbage('restart')
assert(growth<2,'Track lookup allocates in its hot loop: '..growth..' KiB')
local Race=require 'race'
for _,fps in ipairs({8,15,20,24,30,60})do
 local dt=1/fps;math.randomseed(139)
 local r=Race.new(8);r.countdown=0
 for _,c in ipairs(r.cars)do c.model.accel=0;c.aiSpeed=0 end
 local counts={0,0,0,0,0};local peak,total=0,0
 for frame=1,fps*10 do
  for i=2,6 do if r.cars[i].decision<=dt then counts[i-1]=counts[i-1]+1 end end
  Race.step(r,dt,{gas=false,brake=false,steer=0})
  total=total+r.aiDecisions;peak=math.max(peak,r.aiDecisions)
  assert(r.physicsSteps>=1)
 end
 for _,n in ipairs(counts)do assert(n>=39 and n<=41,'Pilot decision frequency changed')end
 assert(total>=195 and total<=205)
 assert(peak<5,'All pilots resynchronized at '..fps..' FPS')
 if fps>=15 then assert(peak<=2,'Decision burst at '..fps..' FPS')end
end
-- Reused input tables must preserve button edges and diagnostic chord behavior.
LEFT,RIGHT,UP,DOWN,BTN_Z,BTN_G,BTN_X,BTN_F,BTN_Q,BTN_E=0,1,2,3,4,13,5,12,14,15
local keys={}
ui=setmetatable({btn=function(k)return keys[k] or false end,stat=function(k)return k==0 and 102400 or 37 end},
 {__index=function()return function()end end})
require 'game'
keys[BTN_X],keys[BTN_E]=true,true;Game.step(1/30);assert(Game.diagnostics)
Game.step(1/30);assert(Game.diagnostics,'Held chord toggled twice')
keys[BTN_X],keys[BTN_E]=false,false;Game.step(1/30)
keys[BTN_X],keys[BTN_E]=true,true;Game.step(1/30);assert(not Game.diagnostics)
keys[BTN_X],keys[BTN_E]=false,false;Game.step(1/30)
keys[DOWN]=true;Game.step(1/30);assert(Game.menu==2)
Game.step(1/30);assert(Game.menu==2,'Held direction repeated edge')
keys[DOWN]=false;Game.step(1/30);keys[DOWN]=true;Game.step(1/30);assert(Game.menu==1)
Game.diagnostics=true;Game.startRace(8);Game.draw()
assert(Game.profile.memory==102400 and Game.profile.cpu==37)
assert(Game.profile.vertices>0 and Game.profile.objects>0)
print('PASS: allocation-free track queries, staggered 4 Hz AI at 8-60 FPS, continuous physics, input edges and hardware-stat diagnostic overlay')
