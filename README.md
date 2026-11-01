# Lupi FPS 3D — estande de tiro (1.2)

Teste de 3D poligonal em primeira pessoa para o Lupi. Cenário, alvos, arma e clarão são malhas com vértices XYZ, projeção em perspectiva e rasterização por `ui.trisfill`. Apenas a interface é 2D. Esta versão substitui o raycasting 2,5D da versão 1.1.

O renderizador faz transformação da câmera, descarte de faces traseiras, recorte no plano próximo e na tela, ordenação por profundidade e validação dos triângulos após conversão para coordenadas inteiras. É 3D por software em Lua usando o rasterizador de triângulos do console; não depende de uma API de GPU 3D. A ordenação usa profundidade média, sem z-buffer, e pode apresentar sobreposição incorreta em geometrias que se intersectam.

## Controles SNES

| Controle | Ação |
| --- | --- |
| Cruz: cima / baixo | Avançar / recuar |
| Cruz: esquerda / direita | Movimento lateral |
| L / R | Virar a câmera |
| B | Pular |
| Y | Atirar; segurar repete os disparos |
| A | Rearmar os seis alvos e zerar os contadores |

O padrão em `config.lua` é `controller="snes"`: L=`BTN_Q`, R=`BTN_E`, B=`BTN_Z`, Y=`BTN_F`, A=`BTN_G`. Para o simulador Raylib direto, `controller="lupinho"` usa W/A/S/D para movimento, G/H para câmera, K para pulo, L para tiro e J para reposição.

Velocidade: 4,2 unidades/s; giro: 1,5 rad/s. Diagonais são normalizadas. O movimento usa subpassos de colisão e o FPS de `ui.stat(7)` quando disponível, com fallback de 60 FPS. B pula uma vez por aperto.

## O que validar

Há seis alvos volumétricos, alguns elevados, divisórias, uma plataforma, uma viga suspensa e uma pedra importada da itch.io. É possível passar sob a viga, colidir com sua parte inferior ao pular e pousar na plataforma.

O tiro usa interseção de raio em XYZ, incluindo a altura dos olhos, o bloqueio pelo cenário e o alvo mais próximo. Não há assistência vertical: alvos elevados exigem ajustar a posição/altura pelo pulo ou plataforma. A mira permanece horizontal. O alvo à frente do ponto inicial pode ser acertado imediatamente. Munição ilimitada; sem áudio.

## Executar

`lupi.yaml` e `game.lua` ficam na raiz para descoberta pelo catálogo. Atualize pelo repositório; o cabeçalho deve mostrar **FPS 3D 1.2 / ESTANDE**.

No Lupinho SDK, selecione a raiz como entrada. O jogo atual não carrega imagens ou sprites: registra sua própria paleta de 32 cores. O padrão `platform="lupinho"` preserva BGR555; a opção `"hardware"` troca os canais vermelho/azul.

Com Node.js:

```sh
node .tools/build.cjs
```

O pacote fica em `.build/fps-3d-release/`, com nove módulos Lua e manifesto. Não inclui o executável do motor. Python e processamento de imagens não são necessários.

## Limites e verificação

- Tela de 480 × 270; área 3D entre y=20 e y=227; paleta de 32 cores.
- Pacote Lua: 21.421 bytes. Pool limitado a 512 triângulos projetados.
- Nos 1.512 pontos/ângulos do teste local: máximo de 186 triângulos enviados por quadro e heap Lua de aproximadamente 241 KiB. Isso não inclui motor, framebuffer ou sistema e não comprova o consumo total nos 4 MB.
- Os tempos no computador não representam FPS do Lupi. Esta versão ainda precisa de teste no aparelho, inclusive para verificar L/R.

```sh
lua .tools/check-renderer.lua
lua .tools/check.lua
node .tools/build.cjs
node .tools/check-discovery.cjs
lua .tools/check-release.lua
lua .tools/profile.lua
```

Os testes verificam perspectiva, altura XYZ, rotação da câmera, recorte, triângulos inteiros válidos, arma volumétrica, ausência de sprites, tiros com oclusão e altura, teto, plataforma, L/R sustentados e movimento em 10/15/30/60/120 FPS.

Para reconstruir uma prévia das chamadas de desenho no Windows após `check.lua`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1
```

A prévia não mede o aparelho. Para regenerar a pedra a partir do OBJ original: `node .tools/import-rock.cjs`. Origem e licenças em [CREDITS.md](CREDITS.md).
