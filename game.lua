require "main"
assert(Game.version=="10.6","Atualizacao incompleta: main.lua 10.6 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
