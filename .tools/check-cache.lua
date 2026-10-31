package.path="./?.lua;"..package.path
local cfg=require "config"
cfg.detail="fast"; cfg.cached_character=false
ui={btn=function() return false end,palset=function() end,camera=function() end,
clip=function() end,cls=function() end,rectfill=function() end,print=function() end,trisfill=function() end}
require "main"
local frames=require "character_frames"
assert(#frames.lookup==frames.angles*frames.poses)
Game.profile_mode=2
local raw={}
Game.capture_triangle=function(t) raw[#raw+1]={table.unpack(t)} end
local checked=0
for direction=0,frames.angles-1 do
    for pose=0,frames.poses-1 do
        raw={}
        Game.facing=direction*math.pi*2/frames.angles
        Game.phase=pose*math.pi*2/frames.poses
        Game.draw()
        local packed=frames.data[frames.lookup[direction*frames.poses+pose+1]]
        assert(#packed%8==0 and #raw==#packed/8,"cached triangle count differs from source projection")
        local previous=math.huge
        for i=1,#raw do
            local t=raw[i]
            local a,b,c,d,e,f,color,z=string.byte(packed,(i-1)*8+1,i*8)
            assert(a+frames.xbase==t[1] and b+frames.ybase==t[2] and c+frames.xbase==t[3] and d+frames.ybase==t[4] and e+frames.xbase==t[5] and f+frames.ybase==t[6],"cached screen coordinates differ")
            assert(color==t[7],"cached color differs")
            assert(math.abs((z+frames.zbase)/32-t[8])<=1/64+1e-9,"cached depth error exceeds quantization")
            assert(z<=previous,"cached triangles must be sorted far to near")
            previous=z
        end
        checked=checked+1
    end
end
print("PASS: "..checked.." cached frames match the 3D source projection; depth order and quantization are valid")
