require "main"
assert(Game.version=="14.1","Atualizacao incompleta: main.lua 14.1 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
