require "main"
assert(Game.version=="13.8","Atualizacao incompleta: main.lua 13.8 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
