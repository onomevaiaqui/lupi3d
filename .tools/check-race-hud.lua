local cfg=require 'config';cfg.save_dir='.build/hud-no-saves/'
local words,labels={},{}
ui=setmetatable({print=function(s,x,y)words[s]=true;labels[x..':'..y]=s end,
 rectfill=function(x,y,x1,y1)
  assert(not (x1-x>40 and y1-y>20) or x==0 and y==0 and x1==480 and y1==270,'Opaque HUD panel returned')
 end},{__index=function()return function()end end})
require 'game'
local C=require 'combat';local Race=require 'race'
Game.startRace(8);local r=Game.race;local p=r.player
r.countdown=0;r.time=4;r.throttle=true
for i=2,6 do r.cars[i].done=true end
for _,item in ipairs(r.combat.pickups)do item.cooldown=999 end
local function hud(...)
 words={};labels={};Game.draw()
 for _,word in ipairs({...})do assert(words[word],'HUD missing '..word)end
end
local function inventory(shot,mine)
 hud('KM/H')
 assert(labels['26:249']=='x'..shot and labels['76:249']=='x'..mine,'Wrong icon quantities')
end
inventory(0,0);hud('VOLTA 1/5','POS 6/6','VIDA 100')
p.laps=1;hud('VOLTA 2/5');p.laps=r.track.laps;hud('VOLTA 5/5');p.laps=0
C.collect(p,'shot');C.collect(p,'mine');inventory(3,2);assert(p.weapon=='shot')
C.select(p);inventory(3,2);assert(p.weapon=='mine')
assert(C.fire(r.combat,p,r.cars));inventory(3,1)
p.cooldown=0;assert(C.fire(r.combat,p,r.cars));inventory(3,0)
C.select(p);inventory(3,0);assert(p.weapon=='shot')
for i=1,3 do p.cooldown=0;assert(C.fire(r.combat,p,r.cars))end
inventory(0,0)
C.collect(p,'nitro');hud('NITRO +10%')
for _,kmh in ipairs({0,1,9,10,72,99,100,999})do p.speed=kmh/6;hud('KM/H')end
local function isolated(lane)
 local r=Race.new(1);r.countdown=0
 for i=2,6 do r.cars[i].done=true end
 for _,item in ipairs(r.combat.pickups)do item.cooldown=999 end
 local p=r.player;local x,z,yaw,_,y=r.track.sample(.5)
 p.x,p.z,p.y,p.yaw,p.progress=x+math.cos(yaw)*(lane or 0),z-math.sin(yaw)*(lane or 0),y,yaw,.5
 p.speed=p.model.speed*1.15
 return r,p
end
local gas={gas=true,brake=false,steer=0}
r,p=isolated();Race.step(r,1/30,gas);assert(not p.slowCause,'Normal asphalt acceleration flagged')
r,p=isolated(12);Race.step(r,1/30,gas);assert(p.slowCause=='FORA DA PISTA')
r,p=isolated();Race.step(r,1/30,{gas=true,brake=true,steer=0});assert(p.slowCause=='FREIO')
r,p=isolated();Race.step(r,1/30,{gas=false,brake=false,steer=0});assert(p.slowCause=='ACELERADOR SOLTO')
r,p=isolated();p.speed=p.speed*1.1;Race.step(r,1/30,gas);assert(p.slowCause=='LIMITE / FIM DO NITRO')
C.damage(p,35,r.combat,'shot');assert(p.slowCause=='ATINGIDO: TIRO')
C.damage(p,35,r.combat,'mine');assert(p.slowCause=='ATINGIDO: MINA')
print('PASS: HUD speed, both inventories, selection, spending, empty states, nitro and actual speed-loss reasons')
