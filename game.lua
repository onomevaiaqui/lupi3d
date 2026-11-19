require "main"
assert(Game.version=="13.3","Atualizacao incompleta: main.lua 13.3 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
