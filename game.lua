require "main"
assert(Game.version=="11.3","Atualizacao incompleta: main.lua 11.3 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
