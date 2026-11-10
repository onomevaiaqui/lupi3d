require "main"
assert(Game.version=="13.2","Atualizacao incompleta: main.lua 13.2 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
