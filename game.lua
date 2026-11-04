require "main"
assert(Game.version=="10.4","Atualizacao incompleta: main.lua 10.4 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
