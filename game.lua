require "main"
assert(Game.version=="12.7","Atualizacao incompleta: main.lua 12.7 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
