require "main"
assert(Game.version=="10.3","Atualizacao incompleta: main.lua 10.3 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
