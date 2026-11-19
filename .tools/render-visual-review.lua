local label=arg[1] or 'visual'
local f;local palette={}
local function emit(k,...)f:write(k,',',table.concat({...},','),'\n')end
ui=setmetatable({palset=function(i,c)palette[i]=c end,cls=function(c)emit('rect',0,0,480,270,c)end,rectfill=function(...)emit('rect',...)end,trisfill=function(...)emit('tri',...)end,print=function(s,x,y,c)emit('text',x,y,c,s)end},{__index=function()return function()end end})
local open=io.open;io=nil;require 'game'
for _,scene in ipairs({{7,'chile'},{9,'paraguai'},{14,'argentina'},{1,'brasil'},{5,'largada'}})do
 math.randomseed(91);Game.startRace(scene[1]);local r=Game.race
 if scene[2]~='largada' then
  r.countdown=0;r.time=4
  for j,car in ipairs(r.cars)do
   local progress=6+(j-1)*0.45;local x,z,yaw,_,y=r.track.sample(progress)
   local lane=((j-1)%3-1)*2.5
   car.x,car.z,car.y,car.yaw=x+math.cos(yaw)*lane,z-math.sin(yaw)*lane,y,yaw;car.speed=12
  end
 end
 f=assert(open('.tools/'..label..'-'..scene[2]..'.csv','w'));Game.draw();f:close()
end
local R=require 'renderer'
for i,model in ipairs(require('car').models)do
 f=assert(open('.tools/'..label..'-car-'..i..'.csv','w'))
 emit('rect',0,0,480,270,4)
 R.begin({x=-3,y=2.4,z=4,yaw=math.atan(3,-4),pitch=-math.atan(2/5)})
 R.submit({x=0,y=0,z=0,mesh=model.mesh});R.flush()
 emit('text',14,12,10,model.name..' / '..math.floor(#model.mesh.f/4)..' TRIANGULOS')
 f:close()
end
local p=assert(open('.tools/palette.csv','w'));for i=0,#require('colors').palette-1 do p:write(i,',',palette[i],'\n')end;p:close()
