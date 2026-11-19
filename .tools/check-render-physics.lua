local root=package.path
local modules={'colors','config','game','geometry','car','track','main','renderer','race','combat','save','audio','scenery','maps'}
local function snapshot(path)
 for _,name in ipairs(modules)do package.loaded[name]=nil end
 package.path=path..'/?.lua;'..root
 local Race=require 'race';local all={}
 for id=1,15 do
  math.randomseed(701);local r=Race.new(id,6,{2,1,2},'TESTE');r.countdown=0
  for i=1,240 do
   Race.step(r,1/30,{gas=true,brake=i%45<5,steer=i%80<40 and 0.2 or -0.3,fire=i%31==0,select=i%43==0})
   if i%30==0 then for _,c in ipairs(r.cars)do for _,key in ipairs({'x','y','z','yaw','speed','hp','ammo','nitro','laps','total'})do all[#all+1]=c[key]end end end
  end
 end
 return all
end
local a,b=snapshot(arg[1] or '.build/render-baseline-13-3'),snapshot('.')
assert(#a==#b);for i,v in ipairs(a)do assert(v==b[i],'Simulation changed at '..i)end
print('PASS: exact physics/combat state equality in 15 seeded eight-second races with six cars')
