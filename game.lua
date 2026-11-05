require "main"
assert(Game.version=="12.8","Atualizacao incompleta: main.lua 12.8 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
