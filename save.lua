local cfg=require "config"
local count=#require("track").names
local function emptyRanks()
    local ranks={}
    for i=1,count do ranks[i]=0 end
    return ranks
end
local S={ranks=emptyRanks(),last=1,sequence=0,status="SEM SAVE"}
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
    local seq,packed,last=prefix:match("^RALLY9|(%d+)|([0-4]+)|(%d+)$")
    if not seq then
        local a,b,c
        seq,a,b,c,last=prefix:match("^RALLY4|(%d+)|([0-4])|([0-4])|([0-4])|([1-3])$")
        if not seq then return nil end
        packed=a..b..c..string.rep("0",count-3)
    end
    seq,last=tonumber(seq),tonumber(last)
    if #packed~=count or seq>100000000 or last<1 or last>count then return nil end
    local ranks={}
    for i=1,count do ranks[i]=tonumber(packed:sub(i,i)) end
    return {sequence=seq,ranks=ranks,last=last}
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
    if best then S.ranks,S.last,S.sequence=best.ranks,best.last,best.sequence;S.status="SAVE CARREGADO" end
    return best~=nil
end
function S.wins()
    local n=0;for _,rank in ipairs(S.ranks) do if rank==1 then n=n+1 end end;return n
end
local pointsByPlace={10,6,3,1}
S.titlePoints=45
function S.pointsFor(place)
    return pointsByPlace[place] or 0
end
function S.points()
    local total=0
    for _,rank in ipairs(S.ranks) do total=total+S.pointsFor(rank) end
    return total
end
function S.canContinue() return S.wins()>0 end
function S.write()
    local seq=S.sequence+1
    local data=string.format("RALLY9|%d|%s|%d",seq,table.concat(S.ranks),S.last)
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
function S.newGame()
    S.ranks=emptyRanks();S.last=1;return S.write()
end
function S.record(track,rank)
    assert(track>=1 and track<=count and rank>=1 and rank<=4)
    if S.ranks[track]==0 or rank<S.ranks[track] then S.ranks[track]=rank end
    S.last=track%count+1
    return S.write()
end
if not io or type(io.open)~="function" then S.status="SAVE INDISPONIVEL" end
S.load()
return S
