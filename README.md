# Lupi 3D — teste de caminhada

Cenário 3D pequeno projetado em Lua sobre `ui.trisfill`, a primitiva 2D do Lupi. Um cavaleiro, quatro árvores, três pedras e um chão de 15 × 15 unidades. Apenas caminhada, câmera e colisão simples; sem combate, pulo, áudio ou dependências de execução externas.

## Versão 0.5: modo leve e diagnóstico no aparelho

O padrão em config.lua agora é detail = "fast": personagem 3D com 95 vértices / 142 triângulos, árvores com 22 / 32, pedras com 10 / 16 e chão com 6 triângulos. Total: 324 triângulos de entrada. Todos os membros e a cabeça são preservados; o conversor simplifica cada componente separadamente. detail = "quality" restaura as malhas da versão 0.4 e seu LOD de árvores. A biblioteca de conversão continua apenas no computador.

No teste local de giro central, o máximo desenhado caiu de 291 para 143 triângulos; o tempo Lua no mesmo profiler geométrico caiu de aproximadamente 0,51 para 0,26 ms por quadro. A memória Lua retida ficou em cerca de 257 KiB, com pico observado de 309 KiB. Isso não mede o motor nem garante a taxa de quadros no aparelho.

O relato de 10 FPS constantes no aparelho motivou quatro perfis. Pressione e solte o botão Z (constante BTN_Z; K no teclado do Lupinho atual) para alternar:

| Perfil | O que desenha |
| --- | --- |
| COMPLETO | Cenário e personagem, padrão |
| CENARIO | Chão, árvores e pedras |
| PERSONAGEM | Só o personagem sobre fundo simples |
| BASE | Limpeza de tela e interface; nenhum triângulo |

Observe o nome, TRI e FPS no topo. Espere cerca de 5 segundos em cada perfil para estabilizar a estatística. Se BASE também ficar perto de 10 FPS, a taxa pode estar limitada pelo custo básico do motor, apresentação de vídeo ou configuração do firmware; simplificar a malha não basta para concluir a causa. Os perfis apenas isolam grupos de desenho, não são um medidor do tempo interno do firmware. FPS -- significa que ui.stat(7) não está disponível.

A caminhada permanece em 2,7 unidades/s e a câmera em 1,5 rad/s, usando o FPS informado pelo firmware. A compensação agora inclui 10 FPS: o intervalo máximo passou a 1/8 s, e a colisão divide deslocamentos longos em subpassos de até 1/60 s. Sem ui.stat(7), usa-se fallback_fps = 60 em config.lua. A correção da velocidade não aumenta a taxa de quadros.

O recorte da versão 0.4 é preservado: só chegam a ui.trisfill coordenadas dentro de x=0..479 e y=20..246. As prévias foram inspecionadas em oito ângulos e os testes cobrem 128 combinações de orientação/pose e intervalos de 10, 15, 30, 60 e 120 Hz.

## Carregamento pelo Lupi

`lupi.yaml`, `game.lua` e todos os módulos Lua estão na raiz, conforme os projetos oficiais. A versão é 0.5 e `public: true`. A estrutura anterior em `src/` foi corrigida porque podia impedir a descoberta pelo catálogo. As pastas `.tools/` e `.assets-source/` ficam ocultas para o codec oficial, que ignora entradas iniciadas com ponto. A saída de build também fica fora da lista de fontes, em `.build/`.

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
| Botão Z / K no teclado | Alternar perfis de diagnóstico |
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
- Geometria compartilhada por instância. Modo fast: cavaleiro 95 vértices / 142 triângulos; árvore 22 / 32; pedra 10 / 16; chão 6 triângulos; cena 324 triângulos. Modo quality: cavaleiro 223 / 374, árvore próxima 63 / 105 e distante 22 / 32, pedra 16 / 28; chão 18; cena com árvores próximas 896 triângulos.
- Fila reutilizável com teto de 768 triângulos, inclusive recortes no plano próximo. `Game.dropped` detecta estouro.
- Projeção em perspectiva, recorte no plano próximo e ordenação por profundidade média. O chão é desenhado primeiro. A ordenação não substitui um z-buffer: interseções e superfícies próximas podem mostrar artefatos neste protótipo.
- Alvo de projeto: reservar a maior parte dos **4 MiB informados** ao firmware/motor. Os testes de Lua no computador mediram aproximadamente **257 KiB retidos e 309 KiB de pico observado**; não representam a RAM total do aparelho. Framebuffers, runtime, pilhas e demais estruturas do motor também precisam caber na memória real.
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
