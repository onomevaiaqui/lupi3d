-- Modern backend verified against lupi-org-br/caio-pernocas: music.loop(path, fade).
-- It is one music stream: brief effects interrupt the engine/theme, then restore it.
local A={available=false,error=false,current=nil,mode="menu",hold=0,priority=0,change=0,brake=0,lastError="",retry=0}
local events={menu={"navigate",0.13,3},confirm={"confirm",0.22,4},red={"red",0.2,4},green={"green",0.3,5},shot={"shot",0.12,6},mine={"mine",0.16,5},hit={"hit",0.18,7},pickup={"pickup",0.2,5},nitro={"nitro",0.5,6},explosion={"explosion",0.45,9},brake={"brake",0.16,2},win={"win",0.8,10},lose={"lose",0.6,10}}
local function hasSfx()
    return type(sfx)=="table" and type(sfx.fx)=="function"
end
A.useSfx=hasSfx()
local function backend()
    if A.useSfx and hasSfx() then return "SFX" end
    if type(music)=="table" and type(music.loop)=="function" then return "FUR" end
    if hasSfx() then return "SFX" end
    return "SEM API"
end
local function start(name,fade)
    if A.retry>0 then return false end
    local kind=backend();A.available=kind~="SEM API"
    if kind~="FUR" then return false end
    local ok,err,reason=pcall(music.loop,"music/"..name,fade or 0.03)
    A.playResult=tostring(err)
    if ok and (err==false or err==nil and type(reason)=="string") then
        ok=false;err=reason or "music.loop recusou arquivo"
    end
    A.error=not ok
    if not ok then A.lastError=tostring(err):sub(1,72);A.retry=2;A.current=nil;return false end
    A.current=name;A.change=0.6;return true
end
local function fileProbe()
    if type(io)~="table" or type(io.open)~="function" then return "ARQ: SEM IO" end
    local ok,result=pcall(function()
        local base=""
        if type(package)=="table" and type(package.searchpath)=="function" and type(package.path)=="string" then
            local found=package.searchpath("main",package.path)
            if found then base=found:match("^(.*[/\\])") or "" end
        end
        local root=io.open(base.."main.lua","rb")
        if not root then return "ARQ: BASE NAO CONFIRMADA" end
        root:close()
        local f=io.open(base.."music/menu.fur","rb")
        if not f then return "ARQ: MENU.FUR AUSENTE" end
        local header=f:read(16);f:close()
        return header and #header==16 and "ARQ: ENCONTRADO" or "ARQ: TRUNCADO"
    end)
    return ok and result or "ARQ: LEITURA FALHOU"
end
function A.test()
    if hasSfx() and type(music)=="table" and type(music.loop)=="function" then
        A.useSfx=not A.useSfx
    end
    A.retry=0;A.hold=0;A.priority=0;A.current=nil
    local kind=backend()
    if kind=="FUR" then
        if start("menu",0.6) then A.hold=8;A.priority=100 end
        A.testInfo="FUR RET:"..(A.playResult or "?").." | "..fileProbe()
    elseif kind=="SFX" then
        if type(music)=="table" and type(music.stop)=="function" then pcall(music.stop,0) end
        -- Use the same pair of built-in sounds as Balao Gatinho's HUD.
        if type(sfx.volume)=="function" then pcall(sfx.volume,0.5) end
        local ok,err,reason=pcall(sfx.fx,62,65,0.5)
        local ok2,err2,reason2=pcall(sfx.fx,198,65)
        local failure=not ok and err or not ok2 and err2 or reason or reason2
        A.error=not ok or not ok2 or err==false or err2==false or type(failure)=="string"
        A.lastError=A.error and tostring(failure or "SFX RECUSADO"):sub(1,72) or ""
        A.legacyTimer=0.3
        A.testInfo="SFX 62/198 RET: "..tostring(err).."/"..tostring(err2)
    else A.testInfo="FIRMWARE SEM API DE AUDIO" end
    A.testTimer=8
end
function A.status()
    local b=backend();A.available=b~="SEM API"
    return A.error and (b.." ERRO") or b
end
function A.scene(mode,force)
    A.mode=mode
    if force then A.hold=0;A.priority=0;A.current=nil end
end
function A.play(event,x,z)
    if x and A.lx and (x-A.lx)^2+(z-A.lz)^2>1024 then return end
    local e=events[event] or events.menu
    local kind=backend();A.available=kind~="SEM API"
    if kind=="FUR" then
        if A.hold>0 and e[3]<A.priority then return end
        if start(e[1]) then A.hold=e[2];A.priority=e[3] end
    elseif kind=="SFX" then
        if A.retry>0 then return end
        if type(sfx.volume)=="function" then pcall(sfx.volume,0.65) end
        local noisy=event=="shot" or event=="explosion" or event=="hit" or event=="brake"
        local ok,err=pcall(sfx.fx,noisy and 3 or 62,noisy and 40 or 65,0.5)
        A.error=not ok;if not ok then A.lastError=tostring(err):sub(1,72);A.retry=2 end
    end
end
function A.update(dt,r,input)
    A.retry=math.max(0,A.retry-dt)
    A.testTimer=math.max(0,(A.testTimer or 0)-dt)
    A.hold=math.max(0,A.hold-dt);A.change=math.max(0,A.change-dt);A.brake=math.max(0,A.brake-dt)
    if r then A.lx,A.lz=r.player.x,r.player.z end
    if r and r.countdown==0 and not r.finished then
        local p=r.player
        if input and (input.brake and p.speed>3 or input.steer~=0 and p.speed>11) and A.brake==0 then
            A.brake=0.8;A.play("brake")
        end
    end
    if A.hold>0 then return end
    local returning=A.priority>0;A.priority=0
    if backend()=="SFX" then
        A.legacyTimer=math.max(0,(A.legacyTimer or 0)-dt)
        if A.legacyTimer==0 and A.retry==0 then
            A.legacyTimer=0.3
            local sample,note
            if A.mode=="race" and r and r.countdown==0 and not r.finished then sample=3;note=math.floor(26+r.player.speed*1.5)
            elseif A.mode=="menu" then
                A.melody=((A.melody or 0)%4)+1;sample=62;note=({60,64,67,72})[A.melody]
            end
            if sample then
                local ok,err=pcall(sfx.fx,sample,note,0.5)
                A.error=not ok;if not ok then A.lastError=tostring(err):sub(1,72);A.retry=2 end
            end
        end
        return
    end
    if backend()~="FUR" then return end
    local desired="menu"
    if A.mode=="race" then
        if not r or r.countdown>0 then return end
        local p=r.player
        desired=p.nitro>0 and "nitro" or p.speed<1 and "engine_idle" or p.speed<6 and "engine_low" or p.speed<11 and "engine_mid" or "engine_high"
    end
    if A.current~=desired and (A.change==0 or returning) then start(desired,desired=="menu" and 0.6 or 0.06) end
end
A.status()
return A
