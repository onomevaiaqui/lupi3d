require "main"
assert(Game.version=="10.0","Atualizacao incompleta: main.lua 10.0 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
