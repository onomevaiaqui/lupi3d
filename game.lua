require "main"
assert(Game.version=="13.7","Atualizacao incompleta: main.lua 13.7 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
