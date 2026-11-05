require "main"
assert(Game.version=="12.3","Atualizacao incompleta: main.lua 12.3 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
