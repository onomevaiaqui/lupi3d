require "main"
assert(Game.version=="11.1","Atualizacao incompleta: main.lua 11.1 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
