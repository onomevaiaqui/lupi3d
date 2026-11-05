require "main"
assert(Game.version=="13.0","Atualizacao incompleta: main.lua 13.0 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
