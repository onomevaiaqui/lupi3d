require "main"
assert(Game.version=="9.1","Atualizacao incompleta: main.lua 9.1 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
