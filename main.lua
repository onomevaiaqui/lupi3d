local models=require("car").models
local geometry=require "geometry"
local cfg=require "config"
local colors=require "colors"
local tracks=require "track"
local geography=require "maps"
local credits={"LUPI COMBAT RALLY 3D"}
local creditsTime=0
local renderer=require "renderer"
local Race=require "race"
local Save=require "save"
local audio=require "audio"
local scenery=require "scenery"
local garagePart,garageReturn,garageMessage=1,"select",""
Game={version="12.9",state="menu",menu=1,selected=1,triangles=0,race=nil,detail=true}
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
    Game.selected=id;Game.race=Race.new(id,Save.model,Save.parts);Game.state="race"
    if type(collectgarbage)=="function" then pcall(collectgarbage,"collect") end
end
local selectedWorld=1
local function selectWorld()
    local world,medal=Save.currentWorld()
    if medal then Game.medal=medal;creditsTime=0;Game.state="trophy";return end
    selectedWorld=world
    Game.selected=tracks.worldOf(Save.last)==world and Save.last or tracks.worlds[world].ids[1]
    Game.state="select"
end
function Game.result()
    local r=Game.race
    if r.prize then return end
    r.prize=Save.reward(r.place)
    local world=r.track.world
    local previous=Save.worldPlace(world)
    Save.record(r.id,r.place,Race.opponentOrder(r),r.prize)
    r.worldPlace=Save.worldPlace(world)
    r.worldPassed=r.worldPlace and r.worldPlace<=3 and (not previous or previous>3)
    Game.state=r.worldPassed and "podium" or "result"
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
            elseif Save.canContinue() then selectWorld();audio.play("menu") end
        end
    elseif Game.state=="garage" then
        if pressed("up") then garagePart=(garagePart-2)%#Save.shop+1;garageMessage="" end
        if pressed("down") then garagePart=garagePart%#Save.shop+1;garageMessage="" end
        if pressed("back") then Game.state=garageReturn
        elseif pressed("ok") then
            if Save.buy(garagePart) then garageMessage="PECA INSTALADA";audio.play("confirm")
            elseif Save.parts[garagePart]>=3 then garageMessage="NIVEL MAXIMO"
            else garageMessage="SALDO INSUFICIENTE" end
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
            Save.newGame(name~="" and name or "PILOTO",modelId);selectWorld()
        end
    elseif Game.state=="select" then
        if pressed("left") or pressed("right") then
            local step=pressed("right") and 1 or -1
            selectedWorld=(selectedWorld-1+step)%#tracks.worlds+1
            Game.selected=tracks.worlds[selectedWorld].ids[1]
            audio.play("menu")
        end
        local range=tracks.worlds[selectedWorld]
        local direction=pressed("down") and 1 or pressed("up") and -1
        if direction then
            for index,id in ipairs(range.ids) do
                if id==Game.selected then
                    Game.selected=range.ids[(index-1+direction)%#range.ids+1]
                    break
                end
            end
            audio.play("menu")
        end
        if pressed("back") then Game.state="menu"
        elseif pressed("selectItem") then garageReturn="select";garageMessage="";Game.state="garage"
        elseif pressed("ok") and selectedWorld<=Save.currentWorld() then Game.startRace(Game.selected) end
    elseif Game.state=="race" then
        if pressed("detail") then Game.detail=not Game.detail end
        if pressed("reset") then Game.startRace(Game.selected)
        else
            Race.step(Game.race,dt,{gas=current.ok,brake=current.brake,fire=pressed("fire"),select=pressed("selectItem"),steer=(current.right and 1 or 0)-(current.left and 1 or 0)})
            if Game.race.finished then Game.result() end
        end
    elseif Game.state=="podium" then
        if pressed("ok") or pressed("back") then
            local _,medal=Save.currentWorld()
            if medal then selectWorld() else Game.state="result" end
        end
    elseif Game.state=="trophy" then
        creditsTime=creditsTime+dt
        if pressed("back") or pressed("ok") then Game.state="menu" end
    elseif Game.state=="result" then
        if pressed("back") then Game.state="menu"
        elseif pressed("selectItem") then garageReturn="result";garageMessage="";Game.state="garage"
        elseif pressed("ok") then selectWorld() end
    end
    audio.scene(Game.state=="race" and "race" or "menu")
    audio.update(dt,Game.state=="race" and Game.race or nil,{brake=current.brake,steer=(current.right and 1 or 0)-(current.left and 1 or 0)})
    previous=current
end
local function rect(x,y,w,h,c) ui.rectfill(x,y,x+w,y+h,colors.index[c]) end
local lampWidths={3,5,6,7,7,8,8,8,8,8,8,7,7,6,5,3}
local function lamp(x,y,color)
    for row,width in ipairs(lampWidths) do
        rect(x-width,y+row-1,width*2,1,color)
    end
end
local function text(s,x,y,c) ui.print(s,x,y,colors.index[c or 9]) end
local function panel()
    rect(40,38,400,190,10);rect(40,38,400,3,8)
    text("LUPI COMBAT RALLY 12.9",122,53,15)
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
        lamp(322+(i-1)*27,88,i==active and color or color+16)
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
local function drawGarage()
    panel()
    text("GARAGEM / "..models[Save.model].name,82,78,15)
    text("SALDO $ "..Save.cash,82,96,8)
    for i,part in ipairs(Save.shop) do
        local y=115+(i-1)*24
        local level=Save.parts[i]
        text((garagePart==i and "> " or "  ")..part.name.." "..level.."/3",80,y,garagePart==i and 15 or 9)
        text(level==3 and "MAX" or ("$ "..Save.price(i)),310,y,8)
        text(part.effect,95,y+10,11)
    end
    text(garageMessage,82,188,8)
    text("B: COMPRAR   Y: VOLTAR",105,208,9)
end
local function flag(country,x,y)
    if country=="BRASIL" then
        rect(x,y,30,18,14)
        ui.trisfill(x+3,y+9,x+15,y+2,x+27,y+9,colors.index[8])
        ui.trisfill(x+3,y+9,x+27,y+9,x+15,y+16,colors.index[8])
        rect(x+12,y+6,6,6,6)
    else
        local top,bottom=7,1
        if country=="ARGENTINA" then top=1
        elseif country=="CHILE" then top,bottom=9,7 end
        rect(x,y,30,6,top)
        rect(x,y+6,30,6,9)
        rect(x,y+12,30,6,bottom)
        if country=="CHILE" then
            rect(x,y+9,30,9,7)
            rect(x,y,10,9,6)
            rect(x+4,y+3,2,3,9)
        else
            rect(x+14,y+8,3,3,8)
        end
    end
end
local landmarks={"CRISTO REDENTOR","BAIRRO DA LIBERDADE","ITAIPU BINACIONAL","SERRAS DE CORDOBA",
    "CORDILHEIRA DOS ANDES","PORTO E MORROS","DESERTO DO ATACAMA","LAGOS DO SUL",
    "PALACIO DE LOPEZ","CERAMICA DE AREGUA","LAGO YPACARAI","PAISAGEM DO CHACO",
    "OBELISCO","MONUMENTO A BANDEIRA","MONTANHAS DOS ANDES"}
local function drawSelect()
    panel()
    local range=tracks.worlds[selectedWorld]
    local map=geography.countries[selectedWorld]
    flag(range.name,59,73)
    text(range.name.." / MAPA DE CIDADES",101,78,15)
    local x,y=60,94
    rect(x,y,153,104,6)
    for _,row in ipairs(map.rows) do rect(x+row[1],y+row[2],row[3]+1,1,14) end
    for _,id in ipairs(range.ids) do
        local point=map.nodes[id]
        if id~=Game.selected then
            rect(x+point[1]-1,y+point[2]-1,2,2,Save.ranks[id]>0 and 9 or 7)
        end
    end
    local point=map.nodes[Game.selected]
    rect(x+point[1]-5,y+point[2]-5,10,10,10)
    rect(x+point[1]-3,y+point[2]-3,6,6,8)
    text(tracks.cities[Game.selected],227,106,15)
    text(landmarks[Game.selected],227,125,9)
    text(tracks.names[Game.selected].." / "..tracks.laps[Game.selected].."V",227,144,9)
    local rank=Save.ranks[Game.selected]
    text(rank>0 and (rank.." LUGAR / "..Save.pointsFor(rank).." PTS") or "PROVA NOVA",227,163,14)
    local locked=selectedWorld>Save.currentWorld()
    text(locked and "PAIS BLOQUEADO" or "3 PROVAS E TOP 3 PARA AVANCAR",227,184,locked and 7 or 11)
    text("ESQ/DIR: PAIS  CIMA/BAIXO: CIDADE",72,202,9)
    text(locked and "CLASSIFIQUE-SE NO PAIS ANTERIOR  Y: MENU" or "B: CORRER  R: GARAGEM  Y: MENU",72,217,9)
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
    local country=tracks.worlds[r.track.world].name
    flag(country,106,20)
    text("PODIO / "..country,146,26,15)
    local standings=Save.standings(r.track.world)
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
    text(r.worldPlace and "CLASSIFICACAO DO MUNDO" or "PLACAR PARCIAL",144,93,8)
    for i,row in ipairs(Save.standings(r.track.world)) do
        local y=105+(i-1)*12
        local color=row.id==1 and 15 or 9
        text(i.."  "..row.name,104,y,color)
        text(row.points.." PTS",315,y,color)
    end
    if r.worldPlace and r.worldPlace>3 then text("MELHORE UMA PROVA PARA AVANCAR",89,178,8)
    elseif r.worldPassed then text("MUNDO CLASSIFICADO",120,178,14) end
    text("PREMIO $ "..r.prize.."   SALDO $ "..Save.cash,82,192,8)
    text("B: PISTAS   R: GARAGEM   Y: MENU",82,210,9)
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
    text("COMBAT RALLY 12.9 / "..r.id,10,6,15);text((Game.detail and "X ALTO " or "X LEVE ")..Game.triangles,282,6,9)
    text(Game.reported_fps and "FPS "..math.floor(Game.reported_fps+0.5) or "FPS --",390,6,9)
    text(string.format("%03d KM/H  VOLTA %d/%d  POS %d/6  VIDA %d",math.floor(p.speed*6+0.5),p.laps,track.laps,Race.position(r),p.hp),10,235,15)
    local item=p.weapon=="shot" and "TIRO" or p.weapon=="mine" and "MINA" or "SEM ARMA"
    text(item.." "..p.ammo..(p.nitro>0 and "  NITRO +10%" or "").." | B GAS A FREIO Y USAR R TROCAR L RESET",10,255,9)
    if r.countdown>0 or r.time<1 then
        rect(190,44,100,28,10)
        local stage=r.countdown>1 and 1 or r.countdown>0 and 2 or 3
        for i,c in ipairs({7,8,14}) do lamp(209+(i-1)*30,50,stage==i and c or c+16) end
        text(stage==3 and "JA!" or stage==2 and "ATENCAO" or "PREPARE",213,78,15)
    end
    if p.respawn>0 then text("CARRO DESTRUIDO / RETORNANDO",133,116,7)
    elseif (p.shortcutNotice or 0)>0 then text("ATALHO / CONTAGEM ZERADA",150,210,7)
    elseif p.offroad then text("GRAMA",215,210,8) end
end
local function drawTrophy()
    local medal=Game.medal
    local color=({8,12,13})[medal]
    rect(0,0,479,269,10)
    text(medal==1 and "PARABENS VOCE VENCEU!" or "PARABENS! CAMPEONATO CONCLUIDO",110,28,15)
    text(({"TACA DE OURO","TACA DE PRATA","TACA DE BRONZE"})[medal],160,53,color)
    rect(195,80,90,13,color)
    rect(201,93,78,13,color)
    rect(208,106,64,13,color)
    rect(219,119,42,10,color)
    rect(235,129,10,20,color)
    rect(215,149,50,7,color)
    rect(204,156,72,7,color)
    text("CREDITOS",197,179,15)
    for i,line in ipairs(credits) do
        local y=232+i*18-math.floor(creditsTime*20)%(82+#credits*18)
        if y>=194 and y<235 then text(line,240-#line*3,y,9) end
    end
    text("B / Y: MENU",177,249,9)
end
function Game.draw()
    colors.register();ui.camera(0,0);ui.clip(0,0,480,270);ui.cls(colors.index[1])
    if Game.state=="race" then drawRace()
    elseif Game.state=="garage" then drawGarage()
    elseif Game.state=="menu" then drawMenu()
    elseif Game.state=="name" then drawName()
    elseif Game.state=="podium" then drawPodium()
    elseif Game.state=="trophy" then drawTrophy()
    elseif Game.state=="select" then drawSelect()
    else drawResult() end
end
