# Lupi FPS — estande de tiro (1.1)

Teste em primeira pessoa inspirado nos FPS dos anos 90: arma na tela, mira e seis alvos em uma sala com divisórias e passagens. O cenário usa raycasting em grade e paredes em faixas verticais de seis pixels. Toda a cena usa retângulos e um sprite nativo para a arma; nenhuma chamada a `ui.trisfill` é feita.

## Controles SNES

| Controle | Ação |
| --- | --- |
| Cruz: cima / baixo | Avançar / recuar |
| Cruz: esquerda / direita | Movimento lateral |
| L / R | Virar a câmera |
| B | Pular |
| Y | Atirar; segurar repete com intervalo entre disparos |
| A | Rearmar todos os alvos e zerar os contadores |

O perfil padrão é `controller="snes"`: L=`BTN_Q`, R=`BTN_E`, B=`BTN_Z`, Y=`BTN_F`, A=`BTN_G`, conforme os nomes documentados pelo Lupi. O formato de cor é configurado separadamente por `platform="lupinho"`, preservando BGR555.

Para teclado/gamepad direto no simulador Raylib, use `controller="lupinho"`: W/A/S/D movem, G/H viram, K pula, L atira e J rearma os alvos.

Velocidade de 4,2 unidades/s e giro de 1,5 rad/s. Diagonais normalizadas e colisão com paredes em subpassos. B dispara um pulo por aperto, sem repetição enquanto fica pressionado. O intervalo de movimento usa `ui.stat(7)` quando disponível, com fallback de 60 FPS e limite de 1/8 s por atualização.

## Atirar nos alvos

O alvo à frente da posição inicial já pode ser acertado. Outros ficam nas laterais e atrás das divisórias; explore as passagens. O disparo é instantâneo, escolhe o alvo mais próximo alinhado horizontalmente e para na primeira parede. Há assistência vertical para tiros durante o pulo. Os alvos acertados desaparecem; o HUD conta acertos e disparos. Use A para repetir o teste. Munição ilimitada, feedback visual de tiro e acerto, sem áudio nesta versão.

## Executar no Lupi

`lupi.yaml` e `game.lua` estão na raiz para descoberta pelo catálogo. Atualize o jogo pelo mesmo repositório; o topo deve mostrar **LUPI FPS 1.1 / ESTANDE**.

No [Lupinho SDK para VS Code](https://github.com/lupi-org-br/lupinho-sdk-vsc), execute **Lupinho SDK: Run** e selecione a raiz do repositório como entrada. O codec oficial processa `img/gun.png` e `img/palette.png`, gerando a paleta, bitmap e descritores de sprites. As pastas iniciadas com ponto ficam fora dessa entrada.

A imagem de paleta garante a presença de todas as cores usadas pela cena. `colors.lua` resolve seus índices na paleta gerada, mesmo que o codec mude a ordem. A arma usa `ui.spr` quando o descritor nativo estiver disponível; há um fallback de retângulos com o mesmo desenho para diagnóstico e execução sem o codec.

### Pacote de execução independente

Com Node.js, Python 3 e Pillow:

```sh
node .tools/build.cjs
```

Defina `LUPI_PYTHON` se o executável Python não estiver no PATH. O resultado fica em **`.build/fps-release/`**, com os scripts, `palette.lua`, bitmap `img/gun` e `lupi_manifest.txt` no formato do simulador. O pacote não inclui um executável do motor. Os identificadores do manifesto são renovados em cada build.

## Recursos e verificação

- Tela: 480 × 270; cena entre y=20 e y=227; paleta de 32 entradas.
- Mapa: 14 × 14 células; 80 raios por quadro, com número limitado de passos por raio.
- Arma: sprite 72 × 96, 6.912 bytes, transparência no índice zero. Dados derivados da arma gratuita da itch.io em [CREDITS.md](CREDITS.md).
- O personagem em terceira pessoa e seu cache de poses não são carregados. O pacote atual tem cerca de 23 KB.
- Nos testes locais, o heap Lua ficou em cerca de 86 KiB no harness funcional e 76 KiB no profiler com sprite nativo simulado. Não inclui os custos do motor, framebuffer ou sistema.
- Não houve execução gráfica no Lupi nesta máquina. FPS real e o comportamento de L/R precisam ser verificados no aparelho. `FPS --` indica que o firmware não forneceu a medição.

```sh
lua .tools/check.lua
node .tools/build.cjs
node .tools/check-discovery.cjs
lua .tools/check-release.lua
lua .tools/profile.lua
```

Os testes cobrem limites dos raios, colisão, movimento e pulo em 10/15/30/60/120 FPS, L/R sustentados, acertos, erros, bloqueio de tiro por parede, prioridade do alvo mais próximo, Y para tiro, A para reposição, recorte dos retângulos, paleta reordenada, carregamento do bitmap e ausência de chamadas de triângulos.

Com ImageMagick instalado, `node .tools/check-codec.cjs` também reproduz a extração de cores em profundidade de 5 bits do codec oficial e verifica que o sprite nativo continua ativo após o arredondamento das cores.

Para visualizar o registro de desenho no Windows após `check.lua`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1
```

Essa prévia reconstrói as chamadas Lua usando o fallback da arma. Não mede o tempo do aparelho.

Para regenerar os derivados da arma, com Pillow:

```sh
python .tools/convert-gun.py
```

O teste anterior em terceira pessoa permanece no histórico, por exemplo no [commit 195b53b](https://github.com/onomevaiaqui/lupi3d/tree/195b53b6ccadfcca13e0a48659332d9d836a83fc). As instruções anteriores de CURTO/ANTIGO/TROCADO não se aplicam ao FPS.
