require "main"
assert(Game.version=="9.9","Atualizacao incompleta: main.lua 9.9 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
