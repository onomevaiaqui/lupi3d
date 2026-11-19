require "main"
assert(Game.version=="13.4","Atualizacao incompleta: main.lua 13.4 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
