local dir,label=arg[1] or '.',arg[2] or 'after'
package.path=dir..'/?.lua;'..package.path
require('config').save_dir='.build/render-test-no-saves/'
local commands
ui=setmetatable({trisfill=function(...)if commands then commands[#commands+1]='[1,'..table.concat({...},',')..']'end end,rectfill=function(...)if commands then commands[#commands+1]='[2,'..table.concat({...},',')..']'end end},{__index=function()return function()end end})
require 'game'
local out=assert(io.open('.build/render-'..label..'.json','w'));out:write('[');local first=true
for id=1,15 do for _,detail in ipairs({true,false})do for view=0,3 do
 math.randomseed(91);Game.detail=detail;Game.startRace(id);local r=Game.race
 if view>0 then
  for j,c in ipairs(r.cars)do
   local progress=(view-1)*r.track.segments/3+0.31+(j-1)*0.45
   local x,z,yaw,_,y=r.track.sample(progress);local lane=((j-1)%3-1)*2.5
   c.x,c.z,c.y,c.yaw=x+math.cos(yaw)*lane,z-math.sin(yaw)*lane,y,yaw;c.speed=12
  end
  r.countdown=0;r.time=4
  if view==3 then
   r.player.nitro=3;r.sliding=true
   local b=r.combat.blasts[1];b.active=true;b.x=r.player.x+3;b.z=r.player.z;b.y=r.player.y+0.12
   local m=r.combat.mines[1];m.active=true;m.x=r.player.x-3;m.z=r.player.z;m.y=r.player.y+0.12
   local t=r.combat.traces[1];t.active=true;t.x=r.player.x;t.z=r.player.z;t.y=r.player.y+0.65;t.yaw=r.player.yaw
  end
 end
 commands={};Game.draw()
 if not first then out:write(',')end;first=false
 out:write('{"id":',id,',"detail":',tostring(detail),',"view":',view,',"commands":[',table.concat(commands,','),']}')
end end end
Game.race.place=1;Game.race.prize=600;Game.medal=1;Game.selected=5
for i,state in ipairs({'menu','name','garage','select','podium','result','trophy'})do
 Game.state=state;commands={};Game.draw()
 out:write(',{"id":0,"detail":true,"view":',i,',"commands":[',table.concat(commands,','),']}')
end
out:write(']');out:close()
