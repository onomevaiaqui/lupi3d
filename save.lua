local cfg=require "config"
local count=#require("track").names
local rivals=require("race").names
local savedOrderWidth=5
local function emptyRanks()
    local ranks={}
    for i=1,count do ranks[i]=0 end
    return ranks
end
local S={ranks=emptyRanks(),name="PILOTO",model=1,orders={},last=1,sequence=0,status="SEM SAVE"}
local base=cfg.save_dir
if not base then
    local path
    if type(package)=="table" and type(package.searchpath)=="function" and type(package.path)=="string" then
        local ok,result=pcall(package.searchpath,"main",package.path)
        if ok then path=result end
    end
    base=path and path:match("^(.*[/\\])") or "./"
end
if base:sub(-1)~="/" and base:sub(-1)~="\\" then base=base.."/" end
local function checksum(s)
    local h=137
    for i=1,#s do h=(h*31+s:byte(i))%65521 end
    return h
end
local function decode(s)
    if type(s)~="string" or #s>128 then return nil end
    local prefix,sum=s:match("^(.*)|(%d+)$")
    if not prefix or checksum(prefix)~=tonumber(sum) then return nil end
    local width=savedOrderWidth
    local seq,packed,last,name,orders,model=prefix:match("^RALLY12|(%d+)|([0-6]+)|(%d+)|([A-Z0-9 ]+)|([0-5]+)|([1-4])$")
    if seq then
        if #name>8 or #orders~=count*width then return nil end
        model=tonumber(model)
    else
    width=3
    model=tonumber(prefix:match("|([1-4])$"))
    local modern=prefix:match("^RALLY11|")
    if modern and not model then return nil end
    if modern then prefix="RALLY10"..prefix:sub(8,-3) else model=1 end
    seq,packed,last,name,orders=prefix:match("^RALLY10|(%d+)|([0-4]+)|(%d+)|([A-Z0-9 ]+)|([0-3]+)$")
    if name and (#name>8 or #orders~=count*3) then return nil end
    if not seq then seq,packed,last=prefix:match("^RALLY9|(%d+)|([0-4]+)|(%d+)$") end
    if not seq then
        local a,b,c
        seq,a,b,c,last=prefix:match("^RALLY4|(%d+)|([0-4])|([0-4])|([0-4])|([1-3])$")
        if not seq then return nil end
        packed=a..b..c..string.rep("0",count-3)
    end
    end
    seq,last=tonumber(seq),tonumber(last)
    if #packed~=count or seq>100000000 or last<1 or last>count then return nil end
    local ranks={}
    for i=1,count do ranks[i]=math.min(#rivals+1,tonumber(packed:sub(i,i))) end
    local results={}
    for i=1,count do
        local order=orders and orders:sub((i-1)*width+1,i*width):gsub("0+$","")
        if order and order~="" then
            if #order~=3 and #order~=savedOrderWidth then return nil end
            for n=1,#order do
                local _,occurrences=order:gsub(tostring(n),"")
                if occurrences~=1 then return nil end
            end
            if #order==savedOrderWidth and ranks[i]>0 then
                local originalRank=tonumber(packed:sub(i,i))
                local _,removed=order:sub(1,originalRank-1):gsub("[45]","")
                ranks[i]=originalRank-removed
            end
            results[i]=order:gsub("[45]","")
        end
    end
    return {sequence=seq,ranks=ranks,last=last,name=name or "PILOTO",orders=results,model=model}
end
local function read(slot)
    if not io or type(io.open)~="function" then return nil end
    local ok,data=pcall(function()
        local f=io.open(base.."rally-save-"..slot..".dat","rb")
        if not f then return nil end
        local s=f:read(129);f:close();return decode(s)
    end)
    return ok and data or nil
end
function S.load()
    local a,b=read(0),read(1)
    local best=a and b and (a.sequence>b.sequence and a or b) or a or b
    if best then S.ranks,S.last,S.sequence=best.ranks,best.last,best.sequence;S.name,S.orders,S.model=best.name,best.orders,best.model;S.status="SAVE CARREGADO" end
    return best~=nil
end
function S.wins()
    local n=0;for _,rank in ipairs(S.ranks) do if rank==1 then n=n+1 end end;return n
end
local pointsByPlace={10,6,3,1}
function S.completed()
    local total=0
    for _,rank in ipairs(S.ranks) do if rank>0 then total=total+1 end end
    return total
end
function S.pointsFor(place)
    return pointsByPlace[place] or 0
end
function S.points()
    local total=0
    for _,rank in ipairs(S.ranks) do total=total+S.pointsFor(rank) end
    return total
end
function S.standings()
    local rows={}
    local names={S.name,table.unpack(rivals)}
    for id,name in ipairs(names) do
        rows[id]={name=name,id=id,points=0,places={0,0,0,0}}
    end
    local function score(row,place)
        row.points=row.points+S.pointsFor(place)
        row.places[place]=row.places[place]+1
    end
    for track,place in ipairs(S.ranks) do
        if place>0 then
            score(rows[1],place)
            local order=S.orders[track]
            if order then
                for i=1,#order do
                    local row=rows[1+tonumber(order:sub(i,i))]
                    score(row,i>=place and i+1 or i)
                end
            end
        end
    end
    table.sort(rows,function(a,b)
        if a.points~=b.points then return a.points>b.points end
        for place=1,#names do
            if a.places[place]~=b.places[place] then return a.places[place]>b.places[place] end
        end
        return a.id<b.id
    end)
    return rows
end
function S.canContinue() return S.wins()>0 end
function S.write()
    local seq=S.sequence+1
    local orders={}
    for i=1,count do
        local order=S.orders[i] or ""
        orders[i]=order..string.rep("0",savedOrderWidth-#order)
    end
    local data=string.format("RALLY12|%d|%s|%d|%s|%s|%d",seq,table.concat(S.ranks),S.last,S.name,table.concat(orders),S.model)
    data=data.."|"..checksum(data)
    local ok=pcall(function()
        assert(io and type(io.open)=="function","io unavailable")
        local f=assert(io.open(base.."rally-save-"..(seq%2)..".dat","wb"))
        local wrote,err=f:write(data);local closed=f:close()
        assert(wrote and closed,err or "write failed")
    end)
    local check=ok and read(seq%2)
    if check and check.sequence==seq then S.sequence=seq;S.status="PROGRESSO SALVO";return true end
    S.status="SAVE INDISPONIVEL";return false
end
function S.newGame(name,model)
    S.ranks=emptyRanks();S.orders={};S.name=name or "PILOTO";S.model=model or 1;S.last=1;return S.write()
end
function S.record(track,rank,order)
    assert(track>=1 and track<=count and rank>=1 and rank<=#rivals+1)
    if S.ranks[track]==0 or rank<S.ranks[track] then S.ranks[track]=rank;S.orders[track]=order
    elseif rank==S.ranks[track] and not S.orders[track] then S.orders[track]=order end
    S.last=track%count+1
    return S.write()
end
if not io or type(io.open)~="function" then S.status="SAVE INDISPONIVEL" end
S.load()
return S
