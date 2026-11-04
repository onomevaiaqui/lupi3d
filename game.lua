require "main"
assert(Game.version=="11.8","Atualizacao incompleta: main.lua 11.8 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
