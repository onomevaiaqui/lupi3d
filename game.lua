require "main"
assert(Game.version=="9.2","Atualizacao incompleta: main.lua 9.2 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
