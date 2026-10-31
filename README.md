# Lupi 3D — teste de caminhada

Cenário 3D pequeno projetado em Lua sobre `ui.trisfill`, a primitiva 2D do Lupi. Um cavaleiro, quatro árvores, três pedras, uma plataforma e um chão de 15 × 15 unidades. Caminhada, pulo, câmera e colisão simples; sem combate, áudio ou dependências de execução externas.

## Versão 0.7: controle SNES, pulo e plataforma

Velocidade aumentada de 2,7 para 4,2 unidades/s. O perfil padrão de controle agora é controller = "snes", independente do formato da paleta. Conforme os nomes publicados na documentação do Lupi: L = BTN_Q, R = BTN_E, B = BTN_Z e Y = BTN_F. L/R giram a câmera, B pula e Y alterna os perfis de diagnóstico. O B não é mais usado para diagnóstico.

A plataforma está à frente da posição inicial, em x=0, z=3,2, com 2,4 × 2,4 unidades e altura 0,55. Tem topo e paredes sólidos e apenas 10 triângulos. Caminhar contra a lateral não permite atravessar nem subir automaticamente: use B e o direcional. É possível pousar, permanecer no topo, pular novamente ou sair pela borda e cair. Segurar B não repete o pulo; solte e aperte novamente.

O impulso vertical é 5,4 unidades/s e a gravidade 15 unidades/s², com ápice de aproximadamente 0,97 unidade acima do apoio. Movimento e gravidade são integrados em subpassos de até 1/60 s. Os testes verificam altura do pulo, colisões laterais, pouso, apoio e queda da borda a 10, 15, 30, 60 e 120 FPS.

A câmera acompanha também a altura dos pés, mantendo o enquadramento relativo ao personagem. Isso permite reutilizar as mesmas poses pré-calculadas durante o pulo e sobre a plataforma, sem adicionar níveis de altura ao cache. O cenário se desloca verticalmente no enquadramento durante a subida/descida. A invariância da projeção foi verificada em diferentes alturas e ângulos.

## Poses 3D pré-calculadas

O teste informado pelo usuário na versão 0.5 mostrou COMPLETO a 20 FPS, CENARIO a 60, PERSONAGEM a 35–40 e BASE a 60. A versão 0.6 concentra a otimização nos cálculos do personagem, mantendo a malha leve de 95 vértices / 142 triângulos. A meta de 30 FPS no aparelho ainda precisa ser confirmada.

A câmera mantém altura relativa aos pés, distância e inclinação fixas. Por isso, sua projeção depende apenas do ângulo relativo à câmera e da pose. O computador gera 64 direções e 16 fases de caminhada, com 576 quadros únicos após deduplicação. No Lupi, o personagem usa esses triângulos já projetados e ordenados, sem refazer a articulação, transformação, projeção, descarte de faces e ordenação interna a cada quadro. A cena continua em 3D: os triângulos do personagem têm profundidade e são intercalados com os objetos do cenário na ordem de desenho.

Os quadros são dados compactados em strings, não tabelas de números por vértice nem imagens. São 310.944 bytes de dados compactados; o módulo Lua gerado ocupa aproximadamente 437 KB em disco. A profundidade é quantizada a 1/32 de unidade, e o ângulo/pose são selecionados pelo vizinho mais próximo; a rotação tem passos de 5,625 graus. Câmera com outra altura, distância, inclinação, zoom ou outra resolução exige regenerar os dados e pode exigir outro formato. O build recusa quadros que não correspondam às versões de models.lua e main.lua.

No mesmo profiler geométrico local, o tempo Lua do PERSONAGEM caiu de cerca de 0,12 para 0,03 ms/quadro; no COMPLETO, de cerca de 0,24 para 0,15 ms. A quantidade de triângulos desenhados não diminuiu nesta versão. Os números não incluem o rasterizador nativo nem garantem 30 FPS no console. Memória Lua retida: aproximadamente 582 KiB; pico observado no teste: 698 KiB. Há uma troca explícita de memória por cálculos por quadro.

O padrão é cached_character = true em config.lua, aplicado apenas a detail = "fast". cached_character = false restaura os cálculos em tempo real para comparar ou modificar a câmera. detail = "quality" continua disponível com o personagem mais detalhado e processamento em tempo real. O cenário e os controles são os mesmos.

## Diagnóstico no aparelho

Pressione e solte Y (BTN_F no perfil SNES; BTN_Q no perfil do emulador Lupinho) para alternar:

| Perfil | O que desenha |
| --- | --- |
| COMPLETO | Cenário e personagem, padrão |
| CENARIO | Chão, árvores e pedras |
| PERSONAGEM | Só o personagem sobre fundo simples |
| BASE | Limpeza de tela e interface; nenhum triângulo |

Observe o nome, TRI e FPS no topo e espere cerca de 5 segundos por perfil. FPS -- significa que ui.stat(7) não está disponível. Os perfis isolam grupos de desenho, sem medir os tempos internos do firmware.

A caminhada usa 4,2 unidades/s e a câmera em 1,5 rad/s, usando o FPS informado pelo firmware. O intervalo máximo é 1/8 s, com subpassos de colisão de até 1/60 s. Sem ui.stat(7), usa-se fallback_fps = 60. Corrigir a velocidade não aumenta a taxa de quadros. O recorte da tela e os testes de movimento em 10, 15, 30, 60 e 120 Hz são preservados.

## Carregamento pelo Lupi

`lupi.yaml`, `game.lua` e todos os módulos Lua estão na raiz, conforme os projetos oficiais. A versão é 0.7 e `public: true`. A estrutura anterior em `src/` foi corrigida porque podia impedir a descoberta pelo catálogo. As pastas `.tools/` e `.assets-source/` ficam ocultas para o codec oficial, que ignora entradas iniciadas com ponto. A saída de build também fica fora da lista de fontes, em `.build/`.

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
| B (BTN_Z) | Pular |
| Y (BTN_F no perfil SNES) | Alternar perfis de diagnóstico |
| Emulador com controller = "lupinho" | W/A/S/D: andar; G/H: câmera; K: pular; L: perfis |

Diagonais têm velocidade normalizada. Botões opostos se cancelam. Colisão circular nas pedras/troncos e limite nas bordas. A animação de passos é procedural sobre os membros do modelo, sem carregar esqueleto ou clipes de animação.

## Simulador e aparelho: ajuste explícito

Há divergências nas referências oficiais consultadas em 31/10/2026:

| Referência | Ombros superiores | Formato da paleta |
| --- | --- | --- |
| Código atual do Lupinho | `BTN_F` / `BTN_G` | BGR555: vermelho nos bits 0–4 |
| Documentação publicada do Lupi | `BTN_Q` / `BTN_E` | RGB555: vermelho nos bits 10–14 |

Em config.lua, platform = "lupinho" mantém a paleta BGR555 que já estava funcionando. Esse campo não escolhe os botões. O campo controller = "snes" usa os ombros BTN_Q/BTN_E da documentação do Lupi. Para usar gamepad/teclado diretamente no emulador Raylib, controller = "lupinho" seleciona BTN_F/BTN_G para os ombros e BTN_Q para o diagnóstico; o pulo continua em BTN_Z. Não há mudança automática de cores ao trocar o perfil de controle.

## Limites e memória

- Resolução: **480 × 270**. Paleta: **32 entradas**, canais de 5 bits, abaixo das 256 permitidas.
- Sem texturas em execução, z-buffer, iluminação dinâmica, física externa ou alocações de objetos por triângulo a cada frame.
- Geometria compartilhada por instância. Modo fast: cavaleiro 95 vértices / 142 triângulos; árvore 22 / 32; pedra 10 / 16; chão 6 triângulos; cena 334 triângulos, incluindo a plataforma. Modo quality: cavaleiro 223 / 374, árvore próxima 63 / 105 e distante 22 / 32, pedra 16 / 28; chão 18; cena com árvores próximas 906 triângulos, incluindo a plataforma.
- Fila reutilizável com teto de 768 triângulos, inclusive recortes no plano próximo. `Game.dropped` detecta estouro.
- Projeção em perspectiva, recorte no plano próximo e ordenação por profundidade média. O chão é desenhado primeiro. A ordenação não substitui um z-buffer: interseções e superfícies próximas podem mostrar artefatos neste protótipo.
- Alvo de projeto: reservar a maior parte dos **4 MiB informados** ao firmware/motor. Os testes de Lua no computador mediram aproximadamente **594 KiB retidos e 713 KiB de pico observado**; não representam a RAM total do aparelho. Framebuffers, runtime, pilhas e demais estruturas do motor também precisam caber na memória real.
- O simulador/código público não fornece aqui uma medição completa do hardware. **Não foi executado no console nem no simulador gráfico nesta máquina. Não há garantia de 60 FPS nem de consumo total abaixo de 4 MiB sem medir nessa versão do aparelho.** A API e a lógica foram verificadas por um harness Lua, e a imagem foi reconstruída das chamadas de desenho.

## Verificar e gerar o pacote

Na raiz do repositório, com Lua 5.4+ e Node.js:

```sh
lua .tools/check.lua
lua .tools/check-models.lua
lua .tools/check-jump.lua
lua .tools/check-cache.lua
lua .tools/profile.lua
node .tools/build.cjs
node .tools/check-discovery.cjs
```

O teste cobre botões liberados retornando zero, avanço/recuo, diagonais, ambos os mapeamentos L/R, movimento relativo à câmera, colisão, borda, giros completos e câmera nas bordas/próxima aos objetos. Mede o heap Lua e verifica crescimento persistente. O build copia apenas os módulos Lua da raiz e gera o manifesto e `BUILD.json` com tamanhos e SHA-256.

Para reconstruir as malhas derivadas dos arquivos de origem CC0:

```sh
node .tools/convert-assets.cjs
lua .tools/bake-character.lua
node .tools/build.cjs
```

O teste check-cache compara os 1.024 quadros de direção/pose com a projeção em tempo real, verifica coordenadas/cores e limita o erro de profundidade a 1/64 de unidade.

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
