local Race=require 'race';local Track=require 'track';local Combat=require 'combat';local cfg=require 'config'
local gas={gas=true,brake=false,steer=0}
local function isolated(id,model)
 local r=Race.new(id,model or 1,{0,0,0},'TESTE');r.countdown=0
 for i=2,6 do r.cars[i].done=true end
 for _,p in ipairs(r.combat.pickups)do p.cooldown=999 end
 return r
end
local function place(r,progress,lane,hint)
 local p=r.player;local x,z,yaw,_,y=r.track.sample(progress)
 p.x,p.z,p.y,p.yaw=x+math.cos(yaw)*(lane or 0),z-math.sin(yaw)*(lane or 0),y,yaw
 p.progress=hint or progress
end
local queries=0
for id=1,15 do
 local t=Track.new(id)
 -- Any actual road center must be recovered as drivable, regardless of stale hint.
 for progress=0,t.segments-1 do
  local x,z,_,_,height=t.sample(progress+.5)
  for hint=0,t.segments-1 do
   local _,d=t.locate(x,z,hint,height);assert(d<=t.driveHalfWidth^2+1e-8,'False grass on asphalt');queries=queries+1
  end
 end
 for _,difficulty in ipairs({1,1.15})do
  cfg.rival_difficulty=difficulty
  local r=isolated(id);local p=r.player;local top=p.model.speed*1.15
  p.speed=top
  for i=1,180 do place(r,.5,0);Race.step(r,1/30,gas);assert(math.abs(p.speed-top)<1e-9 and p.hp==100 and not p.offroad)end
  for _,side in ipairs({-1,1})do
   for i=1,12 do place(r,.5,side*(r.track.halfWidth+r.track.curbWidth/2));Race.step(r,1/30,gas);assert(not p.offroad and math.abs(p.speed-top)<1e-9,'Curb caused speed loss')end
  end
 end
end
cfg.rival_difficulty=1.15
-- Reproduced regression: parallel branch of Viaduto Sul retained as the hint.
local r=isolated(8);place(r,16.5,0,49);r.player.speed=r.player.model.speed*1.15
Race.step(r,.125,gas);assert(not r.player.offroad and math.abs(r.player.speed-17.25)<1e-9 and r.player.hp==100)
for model=1,6 do
 local r=isolated(1,model);local p=r.player;local top=p.model.speed*1.15
 place(r,.5);p.speed=top*1.1;p.nitro=.001
 local last=p.speed
 for i=1,60 do
  place(r,.5);Race.step(r,1/60,gas)
  assert(last-p.speed<=9/60+1e-8,'Nitro expiration snapped speed')
  assert(p.speed>=top-1e-9 and p.speed<=top*1.1+1e-9)
  last=p.speed
 end
 assert(math.abs(p.speed-top)<1e-9 and p.hp==p.maxHP)
end
r=isolated(1);local p=r.player;place(r,.5,12);p.speed=17.25
Race.step(r,.125,gas);assert(p.offroad and p.speed<17.25 and p.hp==100,'Real grass must still slow')
r=isolated(1);p=r.player;place(r,.5);p.speed=17.25
Race.step(r,.1,{gas=true,brake=true,steer=0});assert(p.speed<17.25 and r.braking)
Combat.damage(p,35,r.combat);assert(p.hp==65 and p.hitNotice>0 and p.stun>0)
-- A small excursion must preserve the lap; a large cut must still invalidate it.
r=isolated(1);p=r.player;place(r,10.1);p.speed=0;p.laps=1;p.nextGate=11
place(r,10.1,12);Race.step(r,.01,gas);assert(p.leftCorridor)
place(r,10.3);p.speed=0;Race.step(r,.01,gas);assert(p.laps==1)
place(r,10.3,12);p.speed=0;Race.step(r,.01,gas);assert(p.leftCorridor)
place(r,10.3+r.track.segments/3);p.speed=0;Race.step(r,.01,gas);assert(p.laps==0 and p.shortcutNotice>0)
print('PASS: '..queries..' stale-hint road-center queries, 15-track steady throttle/curbs at both difficulty settings, viaduct recovery, smooth nitro for six models, grass/brake/damage and shortcut rules')
