require "main"
assert(Game.version=="11.9","Atualizacao incompleta: main.lua 11.9 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
