require "main"
assert(Game.version=="10.1","Atualizacao incompleta: main.lua 10.1 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
