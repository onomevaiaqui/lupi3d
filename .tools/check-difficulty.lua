local cfg=require 'config';cfg.save_dir='.build/difficulty-test/'
-- Only remove these two harness-owned files; never touch normal game saves.
os.remove(cfg.save_dir..'rally-save-0.dat');os.remove(cfg.save_dir..'rally-save-1.dat')
local Race=require 'race';local tracks=require 'track';local models=require('car').models
assert(#models==6 and models[5].name=='CHEVETTE' and models[6].name=='KOMBI')
for _,m in ipairs(models) do
 assert(#m.mesh.f/4<=110)
 for i=1,#m.mesh.f,4 do
  for j=0,2 do assert(m.mesh.f[i+j]>=1 and m.mesh.f[i+j]<=#m.mesh.v/3) end
  assert(m.mesh.f[i+3]>=0 and m.mesh.f[i+3]<32)
 end
end
local function packed(p)local t={};for _,v in ipairs(p)do t[#t+1]=table.concat(v)end;return table.concat(t,':')end
for n=1,40 do
 for part=1,3 do
  local before={0,0,0}
  for level=1,3 do
   local old=Race.rivalParts(before,1,'PILOTO'..n);before[part]=level
   local new=Race.rivalParts(before,1,'PILOTO'..n);local changed=0
   for i=1,5 do
    for j=1,3 do
     assert(new[i][j]>=old[i][j] and new[i][j]<=3)
     if new[i][j]>old[i][j] then assert(j==part);changed=changed+1 end
    end
   end
   assert(changed>=1 and changed<=2,'one or two rivals per purchase')
   math.randomseed(n*71);assert(packed(new)==packed(Race.rivalParts(before,1,'PILOTO'..n)))
  end
 end
end
local previous=0
for world=1,4 do
 for _,id in ipairs(tracks.worlds[world].ids) do
  math.randomseed(101);local r=Race.new(id,5,{0,0,0},'TESTE')
  local average=0
  for i=2,6 do average=average+r.cars[i].aiSpeed end
  assert(average>previous,'difficulty must grow in campaign order');previous=average
  assert(#r.cars==6 and r.cars[1].modelId==5)
  for i=1,6 do assert(r.cars[i].hp==r.cars[i].maxHP) end
  r.countdown=0
  for frame=1,180 do Race.step(r,1/30,{gas=true,brake=false,steer=0}) end
  for i=2,6 do assert(r.cars[i].speed>=0 and r.cars[i].speed<=r.cars[i].model.speed*1.15*1.1) end
 end
end
for world=1,4 do
 local id=tracks.worlds[world].ids[1]
 math.randomseed(17);local base=Race.new(id,6,{0,0,0},'TESTE')
 math.randomseed(17);local up=Race.new(id,6,{3,3,3},'TESTE')
 assert(up.player.maxHP==180 and base.player.maxHP==120)
 local baseTotal,upTotal=0,0
 for i=2,6 do
  assert(up.cars[i].maxHP>=base.cars[i].maxHP)
  baseTotal=baseTotal+base.cars[i].aiSpeed;upTotal=upTotal+up.cars[i].aiSpeed
 end
 assert(upTotal>baseTotal,'rival purchases affect actual performance')
end
local Save=require 'save'
for model=1,6 do
 assert(Save.newGame('TESTE',model));Save.cash=900;Save.parts={1,2,3};assert(Save.write())
 Save.model=0;Save.parts={0,0,0};assert(Save.load())
 assert(Save.model==model and table.concat(Save.parts)=='123' and Save.cash==900)
end
-- Existing model IDs keep the same meaning; legacy RALLY11 remains readable.
local prefix='RALLY11|100|100000000|1|ANTIGO|'..string.rep('123',9)..'|4'
local sum=137;for i=1,#prefix do sum=(sum*31+prefix:byte(i))%65521 end
local f=assert(io.open(cfg.save_dir..'rally-save-0.dat','wb'));f:write(prefix..'|'..sum);f:close()
assert(Save.load() and Save.model==4 and Save.name=='ANTIGO')
print('PASS: 6 meshes, 360 purchase events, monotonic 15-track difficulty, upgrades, 6-car simulations, saves for all models and legacy save')
