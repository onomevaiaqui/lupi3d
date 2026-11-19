local Track=require 'track';local Race=require 'race'
local seams=0;local maxJump,maxTurn=0,0
local function angle(a,b)return math.abs((b-a+math.pi)%(2*math.pi)-math.pi)end
for id=1,15 do
 local t=Track.new(id)
 for _,lane in ipairs({-5.8,-2.5,0,2.5,5.8})do
  for i=0,t.segments-1 do
   local ax,az,a,ay=t.sampleLane(i-1e-7,lane);local bx,bz,b,by=t.sampleLane(i+1e-7,lane)
   local jump=math.sqrt((ax-bx)^2+(az-bz)^2)
   assert(jump<0.00001 and math.abs(ay-by)<0.00001,'Discontinuous lane position at boundary')
   assert(angle(a,b)<0.00001,'Discontinuous heading at boundary')
   maxJump=math.max(maxJump,jump);maxTurn=math.max(maxTurn,angle(a,b));seams=seams+1
  end
  local one,len=t.advanceLane(t.segments-.2,60,lane)
  local many=t.segments-.2;for i=1,600 do many=t.advanceLane(many,.1,lane)end
  assert(math.abs(one-many)<1e-8 and len>0,'Distance changes with subdivision')
 end
 -- Actual AI physics must respect its speed budget across every join.
 local r=Race.new(id,1,{0,0,0},'TESTE');r.countdown=0;r.player.respawn=999
 for i=3,6 do r.cars[i].done=true end
 for _,p in ipairs(r.combat.pickups)do p.cooldown=999 end
 local c=r.cars[2]
 for _,lane in ipairs({-5.5,5.5})do for i=0,t.segments-1 do
  c.lane,c.targetLane=lane,lane;c.total=i-.001;c.done=false;c.speed=c.aiSpeed
  c.x,c.z,c.yaw,c.y=r.track.sampleLane(c.total,lane)
  local ax,az=c.x,c.z;local total=c.total
  Race.step(r,.025,{gas=false,brake=false,steer=0})
  local distance=math.sqrt((c.x-ax)^2+(c.z-az)^2)
  assert(distance<=c.speed*.025+1e-8,'AI teleported beyond speed budget')
  assert(c.total>total,'Progress must advance monotonically')
 end end
end
print(string.format('PASS: %d lane joins including lap wrap, continuous position/height/heading, exact multi-segment distance, 15-track AI speed bounds; max join delta %.9f units / %.9f radians',seams,maxJump,maxTurn))
