require "main"
assert(Game.version=="12.4","Atualizacao incompleta: main.lua 12.4 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
