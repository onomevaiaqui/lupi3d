require "main"
assert(Game.version=="11.5","Atualizacao incompleta: main.lua 11.5 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
