local cfg=require 'config';cfg.save_dir='.build/hud-no-saves/'
local words={}
ui=setmetatable({print=function(s,x,y)words[s]=true end},{__index=function()return function()end end})
require 'game'
local C=require 'combat';local Race=require 'race'
Game.startRace(8);local r=Game.race;local p=r.player
r.countdown=0;r.time=4;r.throttle=true
for i=2,6 do r.cars[i].done=true end
for _,item in ipairs(r.combat.pickups)do item.cooldown=999 end
local function hud(...)
 words={};Game.draw()
 for _,word in ipairs({...})do assert(words[word],'HUD missing '..word)end
end
hud('KM/H','TIRO 0','MINA 0','Y: SEM ITEM','R: TROCAR')
C.collect(p,'shot');C.collect(p,'mine');hud('TIRO 3','MINA 2','Y: TIRO')
C.select(p);hud('TIRO 3','MINA 2','Y: MINA')
assert(C.fire(r.combat,p,r.cars));hud('TIRO 3','MINA 1','Y: MINA')
p.cooldown=0;assert(C.fire(r.combat,p,r.cars));hud('MINA 0','Y: SEM ITEM')
C.select(p);hud('TIRO 3','Y: TIRO')
for i=1,3 do p.cooldown=0;assert(C.fire(r.combat,p,r.cars))end
hud('TIRO 0','MINA 0','Y: SEM ITEM')
C.collect(p,'nitro');hud('NITRO +10%')
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
