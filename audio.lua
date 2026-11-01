-- Uses the documented firmware sample bank; no large WAVs loaded in Lua.
local A={available=type(sfx)=="table" and type(sfx.fx)=="function",error=false,engineTimer=0}
local notes={menu=72,red=48,green=84,shot=90,mine=42,hit=32,pickup=79,win=88,lose=40}
function A.play(event)
    A.available=type(sfx)=="table" and type(sfx.fx)=="function"
    if not A.available then return end
    local ok=pcall(sfx.fx,0,notes[event] or 60,0.5)
    if not ok then A.error=true end
end
function A.step(dt,speed)
    A.engineTimer=A.engineTimer-dt
    if speed and speed>0.5 and A.engineTimer<=0 then
        A.engineTimer=0.3
        A.available=type(sfx)=="table" and type(sfx.fx)=="function"
        if A.available then local ok=pcall(sfx.fx,0,math.floor(30+speed*1.2),0.5);if not ok then A.error=true end end
    end
end
return A
