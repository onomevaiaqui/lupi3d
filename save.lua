local cfg=require "config"
local S={ranks={0,0,0},last=1,sequence=0,status="SEM SAVE"}
local base=cfg.save_dir
if not base then
    local path=package.searchpath and package.searchpath("main",package.path)
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
    local seq,a,b,c,last,sum=s:match("^RALLY4|(%d+)|(%d)|(%d)|(%d)|(%d)|(%d+)$")
    if not seq then return nil end
    local prefix=s:match("^(.*)|%d+$")
    seq,a,b,c,last,sum=tonumber(seq),tonumber(a),tonumber(b),tonumber(c),tonumber(last),tonumber(sum)
    if seq>100000000 or a>4 or b>4 or c>4 or last<1 or last>3 or checksum(prefix)~=sum then return nil end
    return {sequence=seq,ranks={a,b,c},last=last}
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
function S.canContinue() return S.wins()>0 end
function S.write()
    local seq=S.sequence+1
    local data=string.format("RALLY4|%d|%d|%d|%d|%d",seq,S.ranks[1],S.ranks[2],S.ranks[3],S.last)
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
    S.ranks={0,0,0};S.last=1;return S.write()
end
function S.record(track,rank)
    assert(track>=1 and track<=3 and rank>=1 and rank<=4)
    if S.ranks[track]==0 or rank<S.ranks[track] then S.ranks[track]=rank end
    S.last=track%3+1
    return S.write()
end
S.load()
return S
