local models=require("car").models
local geometry=require "geometry"
local cfg=require "config"
local colors=require "colors"
local tracks=require "track"
local trackCount=#tracks.names
local renderer=require "renderer"
local Race=require "race"
local Save=require "save"
local audio=require "audio"
local scenery=require "scenery"
Game={version="9.9",state="menu",menu=1,selected=1,triangles=0,race=nil,detail=true}
-- Fixed oblique top-down view; follows position, never the car's heading.
local camera={x=0,y=18,z=0,yaw=math.atan(12,14),pitch=-math.atan(18/math.sqrt(340))}
local frame=0
local titleTime=0
local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
local nameCursor,nameLetters,modelId=1,{},1
local previous={}
local function held(k)
    if k==nil then return false end
    local v=ui.btn(k,0);return v==true or type(v)=="number" and v>0
end
local function timestep()
    if frame%5==0 then
        if type(ui.stat)=="function" then local ok,f=pcall(ui.stat,7);if ok and type(f)=="number" and f==f and f>=5 and f<=240 then Game.fps=f;Game.reported_fps=f end end
    end
    frame=frame+1;return math.min(1/(Game.fps or cfg.fallback_fps),0.125)
end
function Game.startRace(id)
    audio.scene("race",true)
    Game.selected=id;Game.race=Race.new(id,Save.model);Game.state="race"
    if type(collectgarbage)=="function" then pcall(collectgarbage,"collect") end
end
function Game.result()
    local r=Game.race
    local completedBefore=Save.completed()
    if completedBefore<trackCount then
        Save.record(r.id,r.place,Race.opponentOrder(r))
        r.championshipEnded=completedBefore==trackCount-1 and Save.completed()==trackCount
        r.titleWon=r.championshipEnded and Save.standings()[1].id==1
    end
    Game.state=r.titleWon and "podium" or "result"
end
function Game.step(dt)
    dt=math.max(0,math.min(dt or timestep(),0.125))
    local gas,brake,fire,back,reset,selectItem=BTN_Z,BTN_G,BTN_F,BTN_F,BTN_Q,BTN_E
    if cfg.controller=="lupinho" then brake,fire,back,reset,selectItem=BTN_X,BTN_F,BTN_Q,BTN_Q,BTN_E end
    local current={up=held(UP),down=held(DOWN),left=held(LEFT),right=held(RIGHT),ok=held(gas),back=held(back),fire=held(fire),brake=held(brake),reset=held(reset),selectItem=held(selectItem),detail=held(BTN_X) and cfg.controller=="snes",test=held(BTN_X)}
    local function pressed(k) return current[k] and not previous[k] end
    if Game.state=="menu" then
        titleTime=(titleTime+dt)%12
        if pressed("test") then audio.test() end
        if pressed("up") or pressed("down") then Game.menu=3-Game.menu;audio.play("menu") end
        if pressed("ok") then
            if Game.menu==1 then nameLetters={1,37,37,37,37,37,37,37};nameCursor=1;modelId=1;Game.state="name";audio.play("confirm")
            elseif Save.canContinue() then Game.selected=Save.last;Game.state="select";audio.play("menu") end
        end
    elseif Game.state=="name" then
        if pressed("reset") then modelId=(modelId-2)%#models+1 end
        if pressed("selectItem") then modelId=modelId%#models+1 end
        if pressed("left") then nameCursor=(nameCursor-2)%8+1 end
        if pressed("right") then nameCursor=nameCursor%8+1 end
        if pressed("up") then nameLetters[nameCursor]=nameLetters[nameCursor]%#alphabet+1 end
        if pressed("down") then nameLetters[nameCursor]=(nameLetters[nameCursor]-2)%#alphabet+1 end
        if pressed("back") then Game.state="menu"
        elseif pressed("ok") then
            local letters={}
            for i,index in ipairs(nameLetters) do letters[i]=alphabet:sub(index,index) end
            local name=table.concat(letters):match("^%s*(.-)%s*$")
            Save.newGame(name~="" and name or "PILOTO",modelId);Game.selected=1;Game.state="select"
        end
    elseif Game.state=="select" then
        if pressed("left") or pressed("up") then Game.selected=(Game.selected-2)%trackCount+1;audio.play("menu") end
        if pressed("right") or pressed("down") then Game.selected=Game.selected%trackCount+1;audio.play("menu") end
        if pressed("back") then Game.state="menu"
        elseif pressed("ok") then Game.startRace(Game.selected) end
    elseif Game.state=="race" then
        if pressed("detail") then Game.detail=not Game.detail end
        if pressed("reset") then Game.startRace(Game.selected)
        else
            Race.step(Game.race,dt,{gas=current.ok,brake=current.brake,fire=pressed("fire"),select=pressed("selectItem"),steer=(current.right and 1 or 0)-(current.left and 1 or 0)})
            if Game.race.finished then Game.result() end
        end
    elseif Game.state=="podium" then
        if pressed("ok") or pressed("back") then Game.state="result" end
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
    text("LUPI COMBAT RALLY 9.9",122,53,15)
end
local titleCamera={x=-1.90,y=1.83,z=-4.85,yaw=0,pitch=-0.075}
local titleMesh=geometry.mesh()
geometry.append(titleMesh,models[1].mesh,0,0,0)
for _,side in ipairs({-1,1}) do
    local a,b,c,d={0,0.93,0.62},{0,0.58,1.24},{side*0.32,0.52,1.20},{side*0.38,0.74,0.62}
    if side<0 then geometry.quad(titleMesh,a,d,c,b,8)
    else geometry.quad(titleMesh,a,b,c,d,15) end
end
for _,side in ipairs({-1,1}) do
    for _,axle in ipairs({-0.75,0.75}) do
        local fender=geometry.box(0.31,0.21,0.66,8,24,15)
        for i=1,#fender.v,3 do
            if fender.v[i+1]>0 then
                fender.v[i]=fender.v[i]*0.74
                fender.v[i+2]=fender.v[i+2]*0.66
            end
        end
        geometry.append(titleMesh,fender,side*0.65,0.61,axle)
    end
    local x=side*0.48
    local z=1.19
    geometry.quad(titleMesh,{x+0.14,0.53,z},{x+0.14,0.67,z},{x-0.14,0.67,z},{x-0.14,0.53,z},9)
    geometry.quad(titleMesh,{x+0.14,0.67,z},{x+0.07,0.74,z},{x-0.07,0.74,z},{x-0.14,0.67,z},9)
    geometry.quad(titleMesh,{x+0.07,0.46,z},{x+0.14,0.53,z},{x-0.14,0.53,z},{x-0.07,0.46,z},9)
end
local titleCar={mesh=titleMesh,x=0,y=0,z=0,yaw=-2.2}
local stars={{239,27},{268,47},{310,20},{361,39},{398,17},{449,51},{470,23}}
local logoGlyphs={
    L={16,16,16,16,16,16,31},U={17,17,17,17,17,17,14},
    P={30,17,17,30,16,16,16},I={31,4,4,4,4,4,31},
    C={15,16,16,16,16,16,15},O={14,17,17,17,17,17,14},
    M={17,27,21,21,17,17,17},B={30,17,17,30,17,17,30},
    A={14,17,17,31,17,17,17},T={31,4,4,4,4,4,4},
    R={30,17,17,30,20,18,17},Y={17,17,10,4,4,4,4},
    ["3"]={30,1,1,14,1,1,30},D={28,18,17,17,17,18,28}
}
local function drawLogo(label,x,y,scale,color)
    for i=1,#label do
        local glyph=logoGlyphs[label:sub(i,i)]
        if glyph then
            for row,bits in ipairs(glyph) do
                for col=0,4 do
                    if bits & (16 >> col)~=0 then
                        rect(x+col*scale+math.floor((7-row)*scale/5),y+(row-1)*scale,scale+1,scale,color)
                    end
                end
            end
        end
        x=x+6*scale
    end
end
local function drawTitleArt()
    rect(0,0,479,269,10)
    for _,star in ipairs(stars) do rect(star[1],star[2],1,1,9) end
    for y=-9,9 do
        local width=math.floor(math.sqrt(100-y*y))
        rect(418-width,45+y,width*2,1,15)
    end
    ui.trisfill(215,123,302,64,396,123,colors.index[27])
    ui.trisfill(317,123,413,71,479,123,colors.index[11])
    rect(0,123,479,112,26)
    rect(190,125,289,4,11)
    ui.trisfill(260,111,479,87,479,119,colors.index[27])
    ui.trisfill(260,111,479,119,260,125,colors.index[27])
    for i=0,8 do
        local x=266+i*24
        rect(x,117-i*2,12,3,i%2==0 and 7 or 8)
    end
    for i=0,15 do
        if i>=7 then rect(i*30,129,29,4,i%2==0 and 7 or 9) end
        rect(i*30,223,29,5,i%2==0 and 9 or 10)
        rect(i*30,229,29,5,i%2==0 and 10 or 9)
    end
    ui.trisfill(262,207,310,153,315,153,colors.index[9])
    ui.trisfill(262,207,315,153,267,207,colors.index[9])
    ui.trisfill(262,207,439,207,439,210,colors.index[9])
    ui.trisfill(262,207,439,210,262,210,colors.index[9])
    rect(292,61,179,3,12)
    rect(292,75,179,3,11)
    for x=293,453,20 do
        ui.trisfill(x,75,x+15,64,x+19,64,colors.index[12])
        ui.trisfill(x,75,x+19,64,x+4,75,colors.index[12])
    end
    rect(467,62,4,66,11)
    rect(322,76,3,8,11)
    rect(380,76,3,8,11)
    rect(307,83,87,27,0)
    local active=math.floor(titleTime/0.65)%3+1
    for i,color in ipairs({7,8,14}) do
        rect(312+(i-1)*27,88,20,16,i==active and color or color+16)
    end
    titleCar.yaw=-2.2+0.08*math.sin(titleTime*math.pi/2)
    renderer.begin(titleCamera)
    renderer.submit(titleCar)
    renderer.flush()
    drawLogo("LUPI COMBAT",25,20,3,9)
    drawLogo("RALLY",25,46,5,8)
    drawLogo("3D",79,85,4,7)
    rect(26,92,44,3,7)
    rect(137,92,46,3,7)
end
local function drawMenu()
    drawTitleArt()
    for i,label in ipairs({"NOVO JOGO","CONTINUE"}) do
        local y=120+(i-1)*28
        local selected=Game.menu==i
        local border=selected and 8 or 9
        rect(28,y,152,1,border);rect(28,y+22,152,1,border)
        rect(28,y,1,22,border);rect(179,y,1,22,border)
        local color=selected and 8 or 9
        if i==2 and not Save.canContinue() and not selected then color=11 end
        text((selected and "> " or "  ")..label,38,y+7,color)
    end
    text("V"..Game.version,440,255,9)
    text("CRUZ: ESCOLHER  B: CONFIRMAR",18,241,9)
    text("SOM: "..audio.status().."  X: TESTAR",287,241,11)
    if audio.error then text(audio.lastError:sub(1,68),20,256,7)
    elseif audio.testInfo and audio.testTimer>0 then text(audio.testInfo:sub(1,72),20,256,9) end
end
local function drawSelect()
    panel()
    text("SELECIONE A PISTA",158,80,9)
    local first=math.min(math.max(1,Game.selected-2),trackCount-4)
    for i=first,first+4 do
        local name=tracks.names[i]
        local y=100+(i-first)*20
        local rank=Save.ranks[i]
        local status=rank==1 and "VENCIDA" or rank>0 and (rank.." LUGAR") or "NOVA"
        text((Game.selected==i and "> " or "  ")..i.." - "..name,90,y,Game.selected==i and 15 or 9)
        text(status.." "..Save.pointsFor(rank).."P",300,y,rank==1 and 14 or 11)
    end
    text(Save.completed().."/"..trackCount.." PISTAS  B: CORRER  Y: MENU",82,210,9)
end
local garageCamera={x=-1.3,y=2.0,z=-9,yaw=0,pitch=-0.09}
local podiumCamera={x=0,y=3.1,z=-10,yaw=0,pitch=-0.14}
local podiumBlocks,podiumCars={},{}
local garageCar={x=2.4,y=0,z=0,yaw=2.48}
for i,h in ipairs({1.45,0.95,0.56}) do
    local x=({0,-3.25,3.25})[i]
    podiumBlocks[i]={mesh=geometry.box(2.65,h,2.8,11,27,12),x=x,y=h/2,z=0}
    podiumCars[i]={x=x,y=h,z=0,yaw=2.65}
end
local function drawName()
    panel()
    text("NOME DO PILOTO",91,85,15)
    for i,index in ipairs(nameLetters) do
        local x=65+(i-1)*24
        rect(x,106,21,24,i==nameCursor and 8 or 11)
        text(alphabet:sub(index,index),x+7,114,i==nameCursor and 10 or 9)
    end
    text("CRUZ: EDITAR NOME",70,144,9)
    text("L / R: TROCAR CARRO",70,164,9)
    local model=models[modelId]
    renderer.begin(garageCamera)
    garageCar.mesh=model.mesh
    renderer.submit(garageCar)
    renderer.flush()
    text(model.name,280,174,15)
    text(model.trait,280,189,9)
    text("B: CONFIRMAR   Y: VOLTAR",119,210,9)
end
local function drawPodium()
    local r=Game.race
    rect(0,0,480,270,10)
    text("PODIO DO CAMPEONATO",146,26,15)
    local standings=Save.standings()
    renderer.begin(podiumCamera)
    for place,block in ipairs(podiumBlocks) do
        local row=standings[place]
        local id=row.id
        renderer.submit(block)
        local car=podiumCars[place]
        car.mesh=r.cars[id].mesh
        renderer.submit(car)
        local x=({240,140,340})[place]
        local name=row.name
        text(tostring(place),x-3,203,place==1 and 15 or 9)
        text(name,x-#name*3,220,id==1 and 15 or 9)
    end
    renderer.flush()
    text("B: VER PLACAR",169,248,9)
end
local function drawResult()
    local r=Game.race
    panel()
    text(r.track.name.." / "..r.place.." LUGAR / +"..Save.pointsFor(r.place).." PTS NA PROVA",72,78,15)
    if r.place==1 or r.championshipEnded then
    text(r.championshipEnded and "CLASSIFICACAO FINAL" or "PLACAR PARCIAL",144,93,8)
    for i,row in ipairs(Save.standings()) do
        local y=109+(i-1)*16
        local color=row.id==1 and 15 or 9
        text(i.."  "..row.name,104,y,color)
        text(row.points.." PTS",315,y,color)
    end
    else text("TENTE NOVAMENTE OU ESCOLHA OUTRA PISTA",67,132,9) end
    local complete=Save.completed()==trackCount
    local summary=complete and ("CAMPEAO: "..Save.standings()[1].name)
        or (Save.completed().."/"..trackCount.." PISTAS   "..Save.points().." PTS")
    text(summary,120,178,14)
    text("B: ESCOLHER PISTA   Y: MENU",111,210,9)
end
local dustMesh=geometry.mesh()
geometry.quad(dustMesh,{-0.38,0,-0.50},{-0.58,0,0.38},{0.58,0,0.38},{0.38,0,-0.50},15)
local dust={mesh=dustMesh,radius=1}
local gridMark=geometry.mesh()
for _,x in ipairs({-0.93,0.84}) do
    geometry.quad(gridMark,{x,0,-1.42},{x,0,1.42},{x+0.09,0,1.42},{x+0.09,0,-1.42},9)
end
geometry.quad(gridMark,{-0.93,0,-1.42},{-0.93,0,-1.33},{0.93,0,-1.33},{0.93,0,-1.42},9)
local function drawRace()
    local r=Game.race;local p=r.player;local track=r.track
    rect(0,20,480,208,track.theme[1])
    camera.x=p.x-12;camera.z=p.z-14;camera.y=18+p.y*0.4
    renderer.begin(camera)
    local function drawRoad(raised)
        for _,part in ipairs(track.parts) do
            if part.raised==raised then
                renderer.submit(part)
                local dx,dz=part.x-p.x,part.z-p.z
                if dx*dx+dz*dz<225 then renderer.submit(part.trim) end
            end
        end
    end
    drawRoad(false)
    renderer.flush()
    if Game.detail then for _,mark in ipairs(track.markings) do renderer.submit(mark) end;renderer.flush() end
    renderer.submit(track.finish)
    for _,slot in ipairs(r.grid) do slot.mesh=gridMark;renderer.submit(slot) end
    renderer.flush()
    if Game.detail then
        for _,obj in ipairs(track.decor) do renderer.submit(obj) end
    end
    for _,tree in ipairs(track.trees) do
        if Game.detail then
            tree.basic=tree.basic or tree.mesh;tree.mesh=scenery.tree
        else tree.mesh=tree.basic or tree.mesh end
        renderer.submit(tree)
    end
    local function drawObjects(upper)
    local function submit(obj, offset)
        if (track.bridge and obj.y>(offset or 0) or false)==upper then renderer.submit(obj) end
    end
    for _,item in ipairs(r.combat.pickups) do if item.cooldown==0 then submit(item) end end
    for _,mine in ipairs(r.combat.mines) do if mine.active then submit(mine,0.12) end end
    for _,car in ipairs(r.cars) do if car.respawn==0 then
        submit(car)
        if Game.detail and car.nitro>0 then
            car.flame=car.flame or {mesh=scenery.flame,y=0,radius=3}
            car.flame.x,car.flame.z,car.flame.yaw,car.flame.y=car.x,car.z,car.yaw,car.y;submit(car.flame)
        end
    end end
    for _,b in ipairs(r.combat.blasts) do if b.active then submit(b,0.12) end end
    for _,trace in ipairs(r.combat.traces) do if trace.active then submit(trace,0.65) end end
    renderer.flush()
    end
    if Game.detail and p.speed>3 and p.respawn==0
        and (p.offroad or r.sliding) then
        local distance=1.6+(frame%12)*0.07
        dust.x=p.x-math.sin(p.yaw)*distance
        dust.z=p.z-math.cos(p.yaw)*distance
        dust.y,dust.yaw=p.y+0.06,p.yaw
        renderer.submit(dust)
    end
    drawObjects(false)
    if track.bridge then
        drawRoad(true)
        renderer.flush()
        drawObjects(true)
    end
    Game.triangles,Game.dropped=renderer.triangles,renderer.dropped
    rect(0,0,480,20,10);rect(0,228,480,42,10)
    text("COMBAT RALLY 9.9 / "..r.id,10,6,15);text((Game.detail and "X ALTO " or "X LEVE ")..Game.triangles,282,6,9)
    text(Game.reported_fps and "FPS "..math.floor(Game.reported_fps+0.5) or "FPS --",390,6,9)
    text(string.format("%03d KM/H  VOLTA %d/3  POS %d/4  VIDA %d",math.floor(p.speed*6+0.5),p.laps,Race.position(r),p.hp),10,235,15)
    local item=p.weapon=="shot" and "TIRO" or p.weapon=="mine" and "MINA" or "SEM ARMA"
    text(item.." "..p.ammo..(p.nitro>0 and "  NITRO +10%" or "").." | B GAS A FREIO Y USAR R TROCAR L RESET",10,255,9)
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
    elseif Game.state=="name" then drawName()
    elseif Game.state=="podium" and Game.race.titleWon and Save.completed()==trackCount then drawPodium()
    elseif Game.state=="select" then drawSelect()
    else drawResult() end
end
