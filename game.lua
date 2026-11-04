require "main"
assert(Game.version=="8.8","Atualizacao incompleta: main.lua 8.8 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
