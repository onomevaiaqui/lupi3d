package.path="./?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_F,BTN_G,BTN_Q,BTN_E,BTN_Z=4,2,1,3,9,11,5,8,7
local keys={}
ui={btn=function(k) return keys[k] or 0 end,palset=function() end,camera=function() end,
clip=function() end,cls=function() end,rectfill=function() end,print=function() end,
trisfill=function(a,b,c,d,e,f)
    assert(a>=0 and a<=479 and c>=0 and c<=479 and e>=0 and e<=479,"jump render X outside viewport")
    assert(b>=20 and b<=246 and d>=20 and d<=246 and f>=20 and f<=246,"jump render Y outside viewport")
end}
require "main"
local p=Game.platform
local function reset(x,z,y)
    keys={}
    Game.x,Game.z,Game.y,Game.vy,Game.yaw,Game.phase=x,z,y or 0,0,0,0
    Game.grounded=true
    Game.step(0) -- release jump/profile edges without advancing simulation
end
for _,fps in ipairs({10,15,30,60,120}) do
    local dt=1/fps
    reset(0,-3)
    keys[BTN_Z]=true
    local maxY=0
    for _=1,fps*2 do Game.step(dt); maxY=math.max(maxY,Game.y) end
    assert(maxY>0.93 and maxY<0.99,"jump apex depends excessively on FPS")
    assert(Game.y==0 and Game.vy==0 and Game.grounded,"jump must land on the floor")
    assert(Game.profile_mode==0,"B must not change diagnostic profile")
    Game.step(dt)
    assert(Game.y==0,"holding B must not trigger automatic repeat jumps")
    keys={}; Game.step(dt); keys[BTN_Z]=true; Game.step(dt)
    assert(Game.y>0,"releasing and pressing B must trigger a new jump")

    reset(0,0)
    keys[UP]=true
    for _=1,fps do Game.step(dt) end
    assert(Game.z>1.6 and Game.z<p.zmin,"platform side must stop walking")
    assert(Game.y==0,"walking into the platform must not teleport onto the top")

    reset(0,0)
    keys[UP],keys[BTN_Z]=true,true
    local landed=false
    for i=1,fps*2 do
        Game.step(dt)
        if i>1 and Game.grounded and math.abs(Game.y-p.height)<0.00001 then landed=true; break end
    end
    assert(landed,"jump must reach the platform at "..fps.." FPS")
    assert(Game.z>p.zmin and Game.z<p.zmax,"platform landing position")
    keys={}
    for _=1,fps do Game.step(dt) end
    assert(Game.y==p.height and Game.grounded,"player must remain supported on the platform")
    keys[BTN_Z]=true
    local platformApex=Game.y
    for _=1,fps*2 do Game.step(dt); platformApex=math.max(platformApex,Game.y) end
    assert(platformApex>p.height+0.93 and Game.y==p.height and Game.grounded,"jumping from the platform must land back on it")
    keys={}; Game.step(dt)
    keys[UP]=true
    for _=1,fps*2 do Game.step(dt) end
    assert(Game.z>p.zmax+0.3 and Game.y==0 and Game.grounded,"walking off must fall back to the floor")
end
for _,height in ipairs({0,0.55,1.522}) do
    Game.x,Game.y,Game.z=0,height,p.z
    for degrees=0,350,10 do
        Game.yaw=degrees*math.pi/180
        Game.draw()
        assert(Game.dropped==0,"jump/platform view exceeds triangle pool")
    end
end
print("PASS: SNES B jump, no held-button repeat, stable apex, side collision, platform landing/support and falling off at 10/15/30/60/120 FPS")
