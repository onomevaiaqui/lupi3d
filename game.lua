require "main"
assert(Game.version=="9.3","Atualizacao incompleta: main.lua 9.3 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
