require "main"
assert(Game.version=="13.6","Atualizacao incompleta: main.lua 13.6 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
