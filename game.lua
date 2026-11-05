require "main"
assert(Game.version=="12.2","Atualizacao incompleta: main.lua 12.2 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
