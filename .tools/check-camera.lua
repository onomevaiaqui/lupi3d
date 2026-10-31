-- Reproduce sustained L/R input from the initial angle, including every wrap.
package.path="./?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_F,BTN_G,BTN_Q,BTN_E,BTN_Z=4,2,1,3,9,11,5,8,7
local keys,triangles={},0
local captureHash
ui={btn=function(k) return keys[k] or false end,palset=function() end,camera=function() end,
clip=function() end,cls=function() end,rectfill=function() end,print=function() end,
trisfill=function(a,b,c,d,e,f,color)
    for _,v in ipairs({a,b,c,d,e,f}) do assert(v==v and math.abs(v)<1000,"invalid camera projection") end
    assert((c-a)*(f-b)-(d-b)*(e-a)>0,"invalid integer raster triangle")
    triangles=triangles+1
    if captureHash then
        for _,v in ipairs({a,b,c,d,e,f,color}) do captureHash=((captureHash ~ v)*16777619)&0xffffffff end
    end
end}
require "game"
local function trace(test,button)
    Game.x,Game.z,Game.y,Game.vy,Game.yaw,Game.phase,Game.facing=0,0,0,0,0,0,0
    Game.grounded=true;Game.profile_mode=0;Game.camera_test=test
    keys={[button]=true}
    local hashes,angles={},{}
    for i=1,180 do
        Game.step(1/30)
        captureHash=2166136261
        Game.draw()
        hashes[i],angles[i]=captureHash,Game.yaw
    end
    captureHash=nil;keys={};Game.step(0)
    return hashes,angles
end
local right=trace(1,BTN_E)
local swappedLeft=trace(2,BTN_Q)
local left,legacyAngles=trace(1,BTN_Q)
local swappedRight=trace(2,BTN_E)
local _,signedAngles=trace(0,BTN_Q)
assert(signedAngles[1]<0 and legacyAngles[1]>6,"test must exercise the initial L wrap")
for i=1,#right do
    assert(right[i]==swappedLeft[i],"swapped physical L differs from original R geometry")
    assert(left[i]==swappedRight[i],"swapped physical R differs from original L geometry")
    assert(math.abs(math.sin(signedAngles[i])-math.sin(legacyAngles[i]))<1e-12,"signed angle changes camera orientation")
    assert(math.abs(math.cos(signedAngles[i])-math.cos(legacyAngles[i]))<1e-12,"signed angle changes camera orientation")
end
for cameraTest=0,2 do
Game.camera_test=cameraTest
for mode=0,5 do
    for _,button in ipairs({BTN_Q,BTN_E}) do
        Game.x,Game.z,Game.y,Game.vy,Game.yaw,Game.phase=0,0,0,0,0,0
        Game.profile_mode=mode
        keys={[button]=true}
        for _=1,600 do
            Game.step(1/30); Game.draw()
            if cameraTest==0 then assert(Game.yaw>=-math.pi and Game.yaw<math.pi,"invalid signed yaw")
            else assert(Game.yaw>=0 and Game.yaw<math.pi*2,"invalid wrapped yaw") end
            assert(Game.profile_mode==mode,"camera button changed the profile")
            assert(Game.dropped==0,"camera exhausts triangle pool")
        end
        keys={}
        local yaw=Game.yaw
        for _=1,10 do Game.step(1/30);Game.draw() end
        assert(Game.yaw==yaw,"camera continues after release")
    end
end
end
Game.camera_test=0
-- Each direction must also work while walking and jumping near the platform.
for _,button in ipairs({BTN_Q,BTN_E}) do
    Game.x,Game.z,Game.y,Game.vy,Game.yaw,Game.phase=0,0,0,0,0,0
    Game.grounded=true;Game.profile_mode=0
    keys={[button]=true,[UP]=true,[BTN_Z]=true}
    for _=1,120 do Game.step(1/30);Game.draw();assert(Game.dropped==0) end
    keys={};Game.step(1/30)
end
Game.camera_test=0
keys={};Game.step(0)
for expected=1,3 do
    Game.yaw=1
    keys={[BTN_G]=true};Game.step(0);Game.step(0)
    assert(Game.camera_test==expected%3,"A must cycle one camera test per press")
    assert(Game.yaw==0,"changing camera test must reset the angle")
    keys={};Game.step(0)
end
Game.camera_test=2;Game.yaw=1
keys={[BTN_Q]=true};Game.step(1/30)
assert(math.abs(Game.yaw-0.05)<1e-12,"swapped L must start at zero and turn right")
keys={};Game.step(0)
keys={[BTN_E]=true};Game.step(1/30)
assert(Game.yaw>6,"swapped R must restart at zero and turn left")
keys={};Game.step(0)
print("PASS: swapped L/R produces identical original opposite-direction triangle streams; signed L preserves orientation; sustained input works in all camera/profile modes")
