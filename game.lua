require "main"
assert(Game.version=="8.6","Atualizacao incompleta: main.lua 8.6 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
