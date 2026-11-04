require "main"
assert(Game.version=="8.2","Atualizacao incompleta: main.lua 8.2 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
