require "main"
assert(Game.version=="9.6","Atualizacao incompleta: main.lua 9.6 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
