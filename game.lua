require "main"
assert(Game.version=="13.1","Atualizacao incompleta: main.lua 13.1 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
