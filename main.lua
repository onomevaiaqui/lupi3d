local cfg=require "config"
local colors=require "colors"
local tracks=require "track"
local renderer=require "renderer"
local Race=require "race"
local Save=require "save"
local audio=require "audio"
local scenery=require "scenery"
local stadium=require "stadium"
Game={state="menu",menu=1,selected=1,triangles=0,race=nil,detail=true,overview=false}
-- Fixed oblique top-down view; follows position, never the car's heading.
local camera={x=0,y=18,z=0,yaw=math.atan(12,14),pitch=-math.atan(18/math.sqrt(340))}
local frame=0
local previous={}
local function held(k)
    if k==nil then return false end
    local v=ui.btn(k,0);return v==true or type(v)=="number" and v>0
end
local function timestep()
    if frame%15==0 then
        Game.fps=cfg.fallback_fps;Game.reported_fps=nil
        if type(ui.stat)=="function" then local ok,f=pcall(ui.stat,7);if ok and type(f)=="number" and f==f and f>=5 and f<=240 then Game.fps=f;Game.reported_fps=f end end
    end
    frame=frame+1;return math.min(1/(Game.fps or cfg.fallback_fps),0.125)
end
function Game.startRace(id)
    audio.scene("race",true)
    Game.selected=id;Game.race=Race.new(id);Game.state="race";Game.overview=false
    if type(collectgarbage)=="function" then pcall(collectgarbage,"collect") end
end
function Game.result()
    local r=Game.race
    Save.record(r.id,r.place)
    Game.state="result"
end
function Game.step(dt)
    dt=math.max(0,math.min(dt or timestep(),0.125))
    local gas,brake,fire,back,detailKey,testKey=BTN_Z,BTN_G,BTN_E,BTN_F,BTN_Q,BTN_X
    if cfg.controller=="lupinho" then brake,fire,back,detailKey,testKey=BTN_X,BTN_G,BTN_Q,BTN_F,BTN_E end
    local current={up=held(UP),down=held(DOWN),left=held(LEFT),right=held(RIGHT),ok=held(gas),back=held(back),fire=held(fire),brake=held(brake),detail=held(detailKey),test=held(testKey)}
    local function pressed(k) return current[k] and not previous[k] end
    if Game.state=="menu" then
        if pressed("test") then audio.play("confirm") end
        if pressed("up") or pressed("down") then Game.menu=3-Game.menu;audio.play("menu") end
        if pressed("ok") then
            if Game.menu==1 then Save.newGame();Game.selected=1;Game.state="select";audio.play("confirm")
            elseif Save.canContinue() then Game.selected=Save.last;Game.state="select";audio.play("menu") end
        end
    elseif Game.state=="select" then
        if pressed("left") or pressed("up") then Game.selected=(Game.selected-2)%3+1;audio.play("menu") end
        if pressed("right") or pressed("down") then Game.selected=Game.selected%3+1;audio.play("menu") end
        if pressed("back") then Game.state="menu"
        elseif pressed("ok") then Game.startRace(Game.selected) end
    elseif Game.state=="race" then
        if pressed("detail") then Game.detail=not Game.detail end
        if pressed("test") then Game.overview=not Game.overview end
        if pressed("back") then Game.startRace(Game.selected)
        else
            Race.step(Game.race,dt,{gas=current.ok,brake=current.brake,fire=pressed("fire"),steer=(current.right and 1 or 0)-(current.left and 1 or 0)})
            if Game.race.finished then Game.result() end
        end
    elseif Game.state=="result" then
        if pressed("back") then Game.state="menu"
        elseif pressed("ok") then Game.selected=Save.last;Game.state="select" end
    end
    audio.scene(Game.state=="race" and "race" or "menu")
    audio.update(dt,Game.state=="race" and Game.race or nil,{brake=current.brake,steer=(current.right and 1 or 0)-(current.left and 1 or 0)})
    previous=current
end
local function rect(x,y,w,h,c) ui.rectfill(x,y,x+w,y+h,colors.index[c]) end
local function text(s,x,y,c) ui.print(s,x,y,colors.index[c or 9]) end
local function panel()
    rect(40,38,400,190,10);rect(40,38,400,3,8)
    text("LUPI COMBAT RALLY 6.0",122,53,15)
end
local function drawMenu()
    panel()
    text("VENCA DUAS PISTAS DIFERENTES EM PRIMEIRO",74,84,9)
    text((Game.menu==1 and "> " or "  ").."NOVO JOGO",144,114,Game.menu==1 and 15 or 9)
    text((Game.menu==2 and "> " or "  ").."CONTINUE",144,140,Save.canContinue() and (Game.menu==2 and 15 or 9) or 11)
    if not Save.canContinue() then text("CONTINUE: VENCA UMA PISTA PARA LIBERAR",80,172,11)
    else text("VITORIAS "..Save.wins().."/3  /  "..Save.status,90,172,14) end
    text("CRUZ: ESCOLHER    B: CONFIRMAR",114,198,9)
    text("NOVO JOGO ZERA O PROGRESSO SALVO",100,214,11)
    text("SOM: "..audio.status().."   X: TESTAR",135,240,11)
    if audio.error then text(audio.lastError:sub(1,68),20,256,7) end
end
local function drawSelect()
    panel()
    text("SELECIONE A PISTA",158,80,9)
    for i,name in ipairs(tracks.names) do
        local rank=Save.ranks[i]
        local status=rank==1 and "VENCIDA" or rank>0 and (rank.." LUGAR") or "NOVA"
        text((Game.selected==i and "> " or "  ")..i.." - "..name,90,100+i*22,Game.selected==i and 15 or 9)
        text(status,330,100+i*22,rank==1 and 14 or 11)
    end
    text("VITORIAS "..Save.wins().."/2  B: CORRER  Y: MENU",82,210,9)
end
local function drawResult()
    local r=Game.race
    panel()
    text(r.place==1 and "PRIMEIRO LUGAR!" or (r.place.." LUGAR - TENTE NOVAMENTE"),132,88,r.place==1 and 14 or 8)
    text(r.track.name.." / "..string.format("%.1f S",r.time),136,112,9)
    text("PISTAS VENCIDAS: "..Save.wins().."/3",130,138,15)
    if Save.wins()>=2 then text("CAMPEAO DO LUPI COMBAT RALLY!",102,163,14)
    else text("VENCA 2 PISTAS DIFERENTES PARA SER CAMPEAO",64,163,9) end
    text(Save.status,150,186,Save.status=="SAVE INDISPONIVEL" and 7 or 9)
    text("B: ESCOLHER PISTA   Y: MENU",123,211,9)
end
local function drawRace()
    local r=Game.race;local p=r.player;local track=r.track
    if Game.overview then
        rect(0,20,480,208,10)
        camera.x,camera.y,camera.z=-60,96,-72
        camera.yaw=math.atan(60,72);camera.pitch=-math.atan(96/math.sqrt(60*60+72*72));camera.far=220
    else
        rect(0,20,480,208,14)
        camera.x=p.x-12;camera.z=p.z-14;camera.y=(p.y or 0)+18
        camera.yaw=math.atan(12,14);camera.pitch=-math.atan(18/math.sqrt(340));camera.far=nil
    end
    renderer.begin(camera)
    if Game.overview then renderer.submit(track.field);renderer.flush() end
    local function road(part)
        renderer.submit(Game.detail and part or part.basic)
        local dx,dz=part.x-p.x,part.z-p.z
        if Game.overview or dx*dx+dz*dz<324 then renderer.submit(Game.detail and part.trim or part.trimBasic) end
    end
    for _,part in ipairs(track.parts) do if not part.raised then road(part) end end
    renderer.flush()
    if Game.detail then
        for _,mark in ipairs(track.markings) do if mark.y<0.05 then renderer.submit(mark) end end
        renderer.flush()
    end
    renderer.submit(track.finish);renderer.flush()
    -- Raised roadway shares painter sorting with cars: traffic below can be occluded.
    for _,part in ipairs(track.parts) do if part.raised then
        road(part);if Game.detail then renderer.submit(part.bridge) end
    end end
    if Game.detail then
        for _,mark in ipairs(track.markings) do if mark.y>=0.05 then renderer.submit(mark) end end
        for _,obj in ipairs(track.stadium) do renderer.submit(obj) end
        for _,tree in ipairs(track.stadiumTrees) do renderer.submit(tree) end
    end
    if Game.detail then
        for _,obj in ipairs(track.decor) do renderer.submit(obj) end
    end
    for _,tree in ipairs(track.trees) do
        if Game.detail then
            tree.basic=tree.basic or tree.mesh;tree.mesh=stadium.tree
        else tree.mesh=tree.basic or tree.mesh end
        renderer.submit(tree)
    end
    for _,item in ipairs(r.combat.pickups) do if item.cooldown==0 then renderer.submit(item) end end
    for _,mine in ipairs(r.combat.mines) do if mine.active then renderer.submit(mine) end end
    for _,car in ipairs(r.cars) do if car.respawn==0 and car.y<0.02 then
        renderer.submit(car)
        if Game.detail and car.nitro>0 then
            car.flame=car.flame or {mesh=scenery.flame,y=0,radius=3}
            car.flame.x,car.flame.y,car.flame.z,car.flame.yaw=car.x,car.y,car.z,car.yaw;renderer.submit(car.flame)
        end
    end end
    for _,b in ipairs(r.combat.blasts) do if b.active then renderer.submit(b) end end
    for _,trace in ipairs(r.combat.traces) do if trace.active then renderer.submit(trace) end end
    renderer.flush()
    -- Level-aware painter pass prevents the bridge deck covering its own traffic.
    for _,car in ipairs(r.cars) do if car.respawn==0 and car.y>=0.02 then
        renderer.submit(car)
        if Game.detail and car.nitro>0 then
            car.flame=car.flame or {mesh=scenery.flame,y=0,radius=3}
            car.flame.x,car.flame.y,car.flame.z,car.flame.yaw=car.x,car.y,car.z,car.yaw
            renderer.submit(car.flame)
        end
    end end
    renderer.flush()
    Game.triangles,Game.dropped=renderer.triangles,renderer.dropped
    rect(0,0,480,20,10);rect(0,228,480,42,10)
    text("COMBAT RALLY 6.0 / "..r.id,10,6,15);text((Game.detail and "ALTO " or "LEVE ")..Game.triangles,282,6,9)
    text(Game.reported_fps and "FPS "..math.floor(Game.reported_fps+0.5) or "FPS --",390,6,9)
    text(string.format("%03d KM/H  VOLTA %d/3  POS %d/4  VIDA %d",math.floor(p.speed*6+0.5),p.laps,Race.position(r),p.hp),10,235,15)
    local item=p.weapon=="shot" and "TIRO" or p.weapon=="mine" and "MINA" or "SEM ARMA"
    text("R: "..item.." "..p.ammo..(p.nitro>0 and "  NITRO +10%" or "").." | B GAS A FREIO Y RESET L GRAF X VISTA",10,255,9)
    if r.countdown>0 or r.time<1 then
        rect(190,44,100,28,10)
        local stage=r.countdown>1 and 1 or r.countdown>0 and 2 or 3
        for i,c in ipairs({7,8,14}) do rect(198+(i-1)*30,50,22,16,stage==i and c or c+16) end
        text(stage==3 and "JA!" or stage==2 and "ATENCAO" or "PREPARE",213,78,15)
    end
    if p.respawn>0 then text("CARRO DESTRUIDO / RETORNANDO",133,116,7)
    elseif p.offroad then text("GRAMA",215,210,8) end
end
function Game.draw()
    colors.register();ui.camera(0,0);ui.clip(0,0,480,270);ui.cls(colors.index[1])
    if Game.state=="race" then drawRace()
    elseif Game.state=="menu" then drawMenu()
    elseif Game.state=="select" then drawSelect()
    else drawResult() end
end
