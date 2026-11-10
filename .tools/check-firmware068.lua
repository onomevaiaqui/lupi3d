local loader=loadfile;local loaded={}
require=function(name)if loaded[name]~=nil then return loaded[name] end;local value=assert(loader('.build/race-3d-release/'..name..'.lua'))();loaded[name]=value==nil and true or value;return loaded[name]end
package=nil;io=nil;os=nil;debug=nil;collectgarbage=nil
LEFT,RIGHT,UP,DOWN,BTN_Z,BTN_X,BTN_SYSTEM,BTN_F,BTN_G,BTN_Q,BTN_E=0,1,2,3,4,5,7,12,13,14,15
local palette,triangles,loops,cues={},0,0,0
music={loop=function(path,fade)assert(path:match('^music/') and not path:match('%.fur$'));loops=loops+1 end,play=function(path)assert(path:match('^music/'));cues=cues+1 end}
sfx={volume=function(v)assert(v>=0 and v<=1)end,fx=function()error('Undocumented legacy SFX must not override music')end}
ui={btn=function()return false end,stat=function(id)return id==7 and 30 or 0 end,
 palset=function(index,c)assert(index>=0 and index<32 and c>=0 and c<=32767);palette[index]=true end,
 camera=function()end,clip=function()end,cls=function()end,rectfill=function()end,print=function()end,
 trisfill=function(x1,y1,x2,y2,x3,y3,c)assert(palette[c]);for _,x in ipairs({x1,x2,x3})do assert(x>=0 and x<=479)end;for _,y in ipairs({y1,y2,y3})do assert(y>=0 and y<=269)end;triangles=triangles+1 end}
require 'game';update(0);assert(Game.state=='menu' and require('audio').status()=='FUR')
require('audio').play('win');assert(cues>0)
local Race=require 'race'
for id=1,15 do
 Game.startRace(id);Game.draw();assert(#Game.race.cars==6)
 for i=1,120 do Race.step(Game.race,1/30,{gas=true,brake=false,steer=0})end
 Game.draw()
end
Game.selected=5
for _,state in ipairs({'name','garage','select','menu'})do Game.state=state;Game.draw()end
assert(loops>0 and triangles>0, 'audio loops='..loops..' triangles='..triangles)
print('PASS: firmware 0.6.8 API, no IO/OS/package/GC, documented buttons, fixed palette, clipped triangles, 15 six-car races, menus, modern looping and one-shot audio')
