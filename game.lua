require "main"
assert(Game.version=="12.0","Atualizacao incompleta: main.lua 12.0 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
