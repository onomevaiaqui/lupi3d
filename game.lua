require "main"
assert(Game.version=="9.7","Atualizacao incompleta: main.lua 9.7 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
