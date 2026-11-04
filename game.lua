require "main"
assert(Game.version=="10.2","Atualizacao incompleta: main.lua 10.2 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
