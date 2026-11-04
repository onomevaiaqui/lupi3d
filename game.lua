require "main"
assert(Game.version=="11.2","Atualizacao incompleta: main.lua 11.2 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
