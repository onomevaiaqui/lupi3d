require "main"
assert(Game.version=="8.3","Atualizacao incompleta: main.lua 8.3 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
