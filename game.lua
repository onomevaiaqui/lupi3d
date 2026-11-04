require "main"
assert(Game.version=="11.6","Atualizacao incompleta: main.lua 11.6 esperado")

function update(frame)
    Game.step()
    Game.draw()
end
