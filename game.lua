require "main"
assert(Game.version=="8.5","Atualizacao incompleta: main.lua 8.5 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
