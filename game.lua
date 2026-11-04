require "main"
assert(Game.version=="8.4","Atualizacao incompleta: main.lua 8.4 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
