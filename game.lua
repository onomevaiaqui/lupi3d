require "main"
assert(Game.version=="11.0","Atualizacao incompleta: main.lua 11.0 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
