require "main"
assert(Game.version=="10.5","Atualizacao incompleta: main.lua 10.5 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
