require "main"
assert(Game.version=="8.9","Atualizacao incompleta: main.lua 8.9 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
