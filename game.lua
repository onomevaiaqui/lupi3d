require "main"
assert(Game.version=="12.1","Atualizacao incompleta: main.lua 12.1 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
