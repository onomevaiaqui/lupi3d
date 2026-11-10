package.path="./?.lua;"..package.path
local calls={}
CH_ALL=31
music={loop=function(path,fade) assert(type(path)=="string" and path:match("^music/") and fade>=0 and fade<=0.6);calls[#calls+1]=path end,volume=function(v,mask,fade) assert(v==1.0 and mask==31) end}
sfx=nil
local A=require "audio"
assert(A.status()=="FUR")
A.scene("menu",true);A.update(0);assert(calls[#calls]=="music/menu")
A.play("menu");assert(calls[#calls]=="music/navigate")
A.update(0.3);assert(calls[#calls]=="music/menu")
A.test();assert(A.hold==8 and A.testInfo:match("ENCONTRADO"),"diagnostic must confirm actual asset in local app folder")
local protected=#calls;A.play("menu");assert(#calls==protected,"short cues must not interrupt eight-second test")
A.update(4);assert(A.hold==4)
local oldIo=io;io=nil;A.test();assert(A.testInfo:match("SEM IO"));io=oldIo
local oldOpen=io.open
io.open=function(path,mode) if path:match("music/menu%.fur$") then return nil,"missing" end;return oldOpen(path,mode) end
A.test();assert(A.testInfo:match("AUSENTE"),"missing delivered asset must be visible in diagnostic")
io.open=oldOpen
local r={countdown=0,finished=false,player={x=0,z=0,speed=12,nitro=0}}
A.scene("race",true);A.update(1,r,{brake=false,steer=0});assert(calls[#calls]=="music/engine_high")
A.play("explosion");local count=#calls
A.play("shot");assert(#calls==count,"low priority shot must not override explosion")
A.update(0.5,r,{brake=false,steer=0});assert(calls[#calls]=="music/engine_high")
A.update(1,r,{brake=true,steer=0});assert(calls[#calls]=="music/brake")
A.update(0.3,r,{brake=false,steer=0});assert(calls[#calls]=="music/engine_high")
r.player.nitro=5;A.update(1,r,{brake=false,steer=0});assert(calls[#calls]=="music/nitro")
local oldLoop=music.loop;music.loop=function() error("missing audio asset") end
A.play("win");assert(A.error and A.lastError:match("missing audio asset"))
local retry=A.retry;A.play("win");assert(A.retry==retry)
music.loop=oldLoop;A.update(3,r,{brake=false,steer=0});assert(not A.error)
-- Current documented backend: one-shot cues, looping themes, even with legacy SFX present.
local once={};music.play=function(path,fade) once[#once+1]=path end
sfx={fx=function()error('Legacy SFX must not replace documented music backend')end}
A.useSfx=false;A.scene('menu',true);A.play('win')
assert(A.status()=='FUR' and once[#once]=='music/win')
music.play=nil;sfx=nil
-- Lua functions can fail by returning nil, message without raising an exception.
local savedLoop=music.loop;music.loop=function() return nil,"arquivo nao encontrado no player" end
A.test();assert(A.error and A.lastError:match("arquivo nao encontrado"))
music.loop=savedLoop;A.test();assert(not A.error)
music=nil;sfx=nil;assert(A.status()=="SEM API");A.play("shot");A.update(1)
print("PASS: modern music.loop backend, menu theme, engine RPM, priority/restore, braking, nitro, one-shot cues, missing-asset backoff and absent API")
