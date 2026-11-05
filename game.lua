require "main"
assert(Game.version=="12.6","Atualizacao incompleta: main.lua 12.6 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
