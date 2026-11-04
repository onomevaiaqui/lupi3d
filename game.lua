require "main"
assert(Game.version=="9.5","Atualizacao incompleta: main.lua 9.5 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
