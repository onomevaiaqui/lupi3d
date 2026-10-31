# Lupi 3D — teste de caminhada

Cenário 3D pequeno projetado em Lua sobre `ui.trisfill`, a primitiva 2D do Lupi. Um cavaleiro, quatro árvores, três pedras e um chão de 15 × 15 unidades. Apenas caminhada, câmera e colisão simples; sem combate, pulo, áudio ou dependências de execução externas.

## Versão 0.4: movimento e rasterização

A caminhada e a câmera usam unidades por segundo. Quando o firmware fornece ui.stat(7), o intervalo é estimado pelo FPS informado e atualizado a cada 15 chamadas. Sem essa API, usa-se fallback_fps = 60 em config.lua. Caminhada: 2,7 unidades/s, contra 2,1 da versão 0.3 a 60 FPS. A câmera continua em 1,5 rad/s. O intervalo máximo é 1/15 s para limitar saltos após travamentos; quedas abaixo de 15 FPS não são integralmente compensadas. A animação usa o mesmo intervalo.

O topo mostra FPS quando fornecido pelo firmware. FPS -- indica indisponibilidade; não é uma medição de 60 FPS. Essa informação ajuda a distinguir baixa taxa de quadros de velocidade de caminhada. show_stats em config.lua desativa o indicador.

Os triângulos são recortados em Lua para x=0..479 e y=20..246 antes de ui.trisfill. Isso evita que o rasterizador nativo percorra milhares de coordenadas invisíveis: no Lupinho público, a rejeição ocorre dentro de fb_set, depois que os loops por linhas e pixels já começaram. O chão passou de 72 para 18 triângulos. Árvores a mais de 8,5 unidades da câmera usam uma malha de 32 triângulos e retornam à malha de 105 ao chegar a menos de 7,5; essa margem evita alternância contínua na fronteira. O personagem mantém a malha corrigida da versão 0.3.

Comparação no computador, sem medir o console:

| Medida | 0.3 | 0.4 |
| --- | ---: | ---: |
| Máximo de triângulos no giro central de 360 graus | 382 | 291 |
| Memória Lua retida após os testes | ~321 KiB | ~289 KiB |
| Pico observado no teste | ~385 KiB | ~347 KiB |
| Maior área projetada somada de triângulos, em 360 vistas no centro e cantos | 707.616 px | 85.355 px |
| Tempo Lua por quadro no mesmo profiler geométrico | ~0,61 ms | ~0,51 ms |

A área projetada é uma estimativa de trabalho de rasterização, incluindo áreas invisíveis, e não uma contagem medida de pixels nem uma taxa de FPS. Não inclui todos os custos do motor. As malhas foram inspecionadas em oito ângulos; os testes verificam 128 combinações de orientação/pose, recorte da tela e movimento/câmera com intervalos de 15, 30, 60 e 120 Hz.

## Carregamento pelo Lupi

`lupi.yaml`, `game.lua` e todos os módulos Lua estão na raiz, conforme os projetos oficiais. A versão é 0.4 e `public: true`. A estrutura anterior em `src/` foi corrigida porque podia impedir a descoberta pelo catálogo. As pastas `.tools/` e `.assets-source/` ficam ocultas para o codec oficial, que ignora entradas iniciadas com ponto. A saída de build também fica fora da lista de fontes, em `.build/`.

## Executar

1. Instale o [Lupinho SDK para VS Code](https://github.com/lupi-org-br/lupinho-sdk-vsc) e o Docker exigido pela extensão.
2. Execute **Lupinho SDK: Run**, escolhendo **a raiz deste repositório** (a pasta que contém `lupi.yaml` e `game.lua`) como entrada e uma pasta externa como destino.
3. A extensão compila e abre o simulador. `game.lua` é o ponto de entrada, seguindo o projeto oficial `primeiro-jogo`.

Alternativa para um simulador já compilado: execute `node .tools/build.cjs`; a pasta **`.build/release/`** contém `game.lua`, os módulos e `lupi_manifest.txt`. Use essa pasta como diretório do jogo no carregador do seu simulador. Ela não contém um executável do Lupi/Lupinho.

O SDK pode gerar `palette.lua`, mas este teste usa `colors.lua` para preservar sua paleta própria de 32 entradas. Não requer imagens, sprites, mapas ou importador 3D no console. Os arquivos GLB/OBJ de origem ficam na pasta oculta `.assets-source/` e não vão para a RAM do jogo.

## Controles

| Controle | Ação |
| --- | --- |
| Cruz: cima / baixo | Caminhar para frente / trás em relação à câmera |
| Cruz: esquerda / direita | Caminhar lateralmente em relação à câmera |
| Ombro superior L / R | Girar a câmera ao redor do personagem |
| Teclado no Lupinho atual | W/A/S/D para andar; G/H para câmera |

Diagonais têm velocidade normalizada. Botões opostos se cancelam. Colisão circular nas pedras/troncos e limite nas bordas. A animação de passos é procedural sobre os membros do modelo, sem carregar esqueleto ou clipes de animação.

## Simulador e aparelho: ajuste explícito

Há divergências nas referências oficiais consultadas em 31/10/2026:

| Referência | Ombros superiores | Formato da paleta |
| --- | --- | --- |
| Código atual do Lupinho | `BTN_F` / `BTN_G` | BGR555: vermelho nos bits 0–4 |
| Documentação publicada do Lupi | `BTN_Q` / `BTN_E` | RGB555: vermelho nos bits 10–14 |

O padrão de **`config.lua` é `platform = "lupinho"`**, conferido contra o código do simulador. Para testar o firmware descrito na documentação, altere para **`platform = "hardware"`** e recompile. Se o seu firmware usar outro mapeamento, ajuste `Game.step()` em `main.lua` conforme essa versão. Não usamos números fixos de botões nem supomos que os dois ambientes são idênticos.

## Limites e memória

- Resolução: **480 × 270**. Paleta: **32 entradas**, canais de 5 bits, abaixo das 256 permitidas.
- Sem texturas em execução, z-buffer, iluminação dinâmica, física externa ou alocações de objetos por triângulo a cada frame.
- Geometria compartilhada por instância: cavaleiro 223 vértices / 374 triângulos; árvore próxima 63 / 105; árvore distante 22 / 32; pedra 16 / 28. Chão: 18 triângulos. Total de entrada com todas as árvores próximas: 896 triângulos; triângulos fora da tela e degenerados são descartados antes do desenho.
- Fila reutilizável com teto de 768 triângulos, inclusive recortes no plano próximo. `Game.dropped` detecta estouro.
- Projeção em perspectiva, recorte no plano próximo e ordenação por profundidade média. O chão é desenhado primeiro. A ordenação não substitui um z-buffer: interseções e superfícies próximas podem mostrar artefatos neste protótipo.
- Alvo de projeto: reservar a maior parte dos **4 MiB informados** ao firmware/motor. Os testes de Lua no computador mediram aproximadamente **289 KiB retidos e 347 KiB de pico observado**; não representam a RAM total do aparelho. Framebuffers, runtime, pilhas e demais estruturas do motor também precisam caber na memória real.
- O simulador/código público não fornece aqui uma medição completa do hardware. **Não foi executado no console nem no simulador gráfico nesta máquina. Não há garantia de 60 FPS nem de consumo total abaixo de 4 MiB sem medir nessa versão do aparelho.** A API e a lógica foram verificadas por um harness Lua, e a imagem foi reconstruída das chamadas de desenho.

## Verificar e gerar o pacote

Na raiz do repositório, com Lua 5.4+ e Node.js:

```sh
lua .tools/check.lua
lua .tools/check-models.lua
lua .tools/profile.lua
node .tools/build.cjs
node .tools/check-discovery.cjs
```

O teste cobre botões liberados retornando zero, avanço/recuo, diagonais, ambos os mapeamentos L/R, movimento relativo à câmera, colisão, borda, giros completos e câmera nas bordas/próxima aos objetos. Mede o heap Lua e verifica crescimento persistente. O build copia apenas os módulos Lua da raiz e gera o manifesto e `BUILD.json` com tamanhos e SHA-256.

Para reconstruir as malhas derivadas dos arquivos de origem CC0:

```sh
node .tools/convert-assets.cjs
node .tools/build.cjs
```

O conversor usa meshoptimizer 1.3.0 (MIT, incluído em .tools/vendor/) para simplificar cada componente com limite de erro. Vértices coincidentes são soldados sem agrupamento espacial em grade. A cabeça é mantida dentro do capacete, os braços são abaixados e as cores são chapadas com duas intensidades. Não precisa instalar Blender ou pacotes npm.

Prévia de diagnóstico no Windows, após o teste:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1
```

Isso gera `.tools/preview.png` usando as chamadas reais do código Lua com um substituto de `ui`. A fonte/rasterização da prévia pode diferir do Lupinho.

## Referências oficiais

- [Lupi: documentação](https://lupi.api.br/docs/) e [entrada de controles](https://lupi.api.br/docs/system.html).
- [Lupinho, revisão c2eb503](https://github.com/lupi-org-br/lupinho/tree/c2eb503e6842766458bd3cad4556aa0c1a57daa3): funções, cores e mapeamento real do simulador.
- [Projeto inicial, revisão fd769b1](https://github.com/lupi-org-br/primeiro-jogo/tree/fd769b1eec35cf1e77c221887966a22716c3e7e2): estrutura e entrada.
- [Codec, revisão 3e8c662](https://github.com/lupi-org-br/lupi-codec/tree/3e8c66299a4606b36b9f490212acc44e084a6aa2): estrutura do manifesto Lua.

Assets e licenças: veja [CREDITS.md](CREDITS.md).
