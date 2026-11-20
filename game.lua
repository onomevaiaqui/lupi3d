require "main"
assert(Game.version=="14.0","Atualizacao incompleta: main.lua 14.0 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
