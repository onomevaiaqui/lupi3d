require "main"
assert(Game.version=="12.9","Atualizacao incompleta: main.lua 12.9 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
