# Lupi Oval 3D — Fusquinha (2.0)

Pequeno jogo de corrida em 3D poligonal para testar o Lupi. Pista oval, zebras vermelhas/brancas, chegada quadriculada e carro original inspirado na silhueta do Fusca. A câmera acompanha o carro por trás. Complete três voltas no sentido inicial.

| Controle SNES | Ação |
| --- | --- |
| B | Acelerar |
| A | Frear |
| Direcional esquerda / direita | Esterçar |

Soltar B desacelera gradualmente. A tem prioridade sobre B. Não há marcha a ré; o carro esterça quando está em movimento. Sair do asfalto reduz a velocidade. Para repetir a prova, reinicie o jogo.

O padrão é `controller="snes"`, B=`BTN_Z` e A=`BTN_G`. No modo direto do simulador, `controller="lupinho"`, B usa `BTN_Z` e A usa `BTN_X`. As cores mantêm o BGR555 que funcionou no teste anterior; `platform="hardware"` troca os canais vermelho/azul.

## Como funciona

Toda a pista, carro e linha de chegada usam vértices XYZ, perspectiva e `ui.trisfill`. Apenas a interface é 2D. O renderizador do teste FPS foi preservado, com suporte adicional à rotação da malha do carro. Há descarte de faces traseiras, recorte próximo/na tela e ordenação por profundidade média, sem z-buffer ou iluminação dinâmica.

O carro tem capô curto, cabine facetada e curva, para-lamas, quatro rodas, para-choques, faróis e lanternas. A malha é original, criada em código para este teste; não é um modelo oficial da Volkswagen.

A física usa velocidade em unidades por segundo, aceleração, freio, arrasto e esterçamento dependente da velocidade. As atualizações são divididas em passos de até 1/60 s. A pista usa uma elipse de raios 18 e 28, dividida em 24 segmentos. A grama desacelera o carro, sem barreiras na borda da pista. Quatro setores precisam ser atravessados na ordem para validar uma volta; cruzar a chegada de ré não soma voltas. A primeira passagem inicia a contagem, e a terceira volta encerra a prova.

## Orçamento

| Elemento | Triângulos da malha |
| --- | ---: |
| Carro | 176 |
| Asfalto e zebras | 144 |
| Chegada quadriculada | 32 |
| Terreno | 2 |
| Total | 354 |

Na posição inicial são enviados 157 triângulos ao rasterizador. Em 288 posições/ângulos locais, o pico foi 227, sem estouro do pool de 512. A paleta mantém 32 cores e a tela é 480 x 270.

O pacote tem oito módulos Lua, aproximadamente 16,3 KB. O harness local reteve cerca de 268 KiB de heap Lua; isso não inclui motor, framebuffer ou sistema. FPS e consumo total nos 4 MB ainda precisam de teste no console. Os aproximadamente 26 FPS relatados anteriormente pertencem ao FPS 3D, não a este jogo de corrida.

## Executar e verificar

`lupi.yaml` e `game.lua` permanecem na raiz para descoberta pelo Lupi. O cabeçalho deve mostrar **OVAL 3D 2.0 / FUSQUINHA**.

Com Lua e Node.js:

```sh
lua .tools/check-renderer.lua
lua .tools/check.lua
node .tools/build.cjs
node .tools/check-discovery.cjs
lua .tools/check-release.lua
```

O build fica em `.build/race-3d-release/`, com os oito módulos e manifesto; não inclui o motor. Não requer imagens, Python ou processamento de assets.

Os testes verificam aceleração e freio em 10/15/26/30/60/120 FPS, prioridade do freio, direção, grama, checkpoints, chegada e três voltas completas usando os mesmos comandos do jogo. Também verificam projeção, rotação de malhas, recorte, coordenadas inteiras, paleta e pacote compilado.

No Windows, uma prévia pode ser reconstruída após `check.lua`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1
```

O FPS anterior permanece no [commit 9b0bff6](https://github.com/onomevaiaqui/lupi3d/tree/9b0bff67e255b9d45c1b78d2fa9d3b6b80f4dec4).
