require "main"
assert(Game.version=="11.4","Atualizacao incompleta: main.lua 11.4 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
