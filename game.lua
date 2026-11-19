require "main"
assert(Game.version=="13.9","Atualizacao incompleta: main.lua 13.9 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
