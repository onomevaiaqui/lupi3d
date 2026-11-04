require "main"
assert(Game.version=="9.4","Atualizacao incompleta: main.lua 9.4 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
