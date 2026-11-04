require "main"
assert(Game.version=="8.7","Atualizacao incompleta: main.lua 8.7 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
