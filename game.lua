require "main"
assert(Game.version=="11.7","Atualizacao incompleta: main.lua 11.7 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
