require "main"
assert(Game.version=="9.0","Atualizacao incompleta: main.lua 9.0 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
