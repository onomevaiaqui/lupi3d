require "main"
assert(Game.version=="9.8","Atualizacao incompleta: main.lua 9.8 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
