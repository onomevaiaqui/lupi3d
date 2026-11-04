require "main"
assert(Game.version=="10.7","Atualizacao incompleta: main.lua 10.7 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
