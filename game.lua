require "main"
assert(Game.version=="13.5","Atualizacao incompleta: main.lua 13.5 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
