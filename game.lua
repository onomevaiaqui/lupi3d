require "main"
assert(Game.version=="12.5","Atualizacao incompleta: main.lua 12.5 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
