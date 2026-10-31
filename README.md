# Lupi 3D — teste de caminhada

Cenário 3D pequeno projetado em Lua sobre `ui.trisfill`, a primitiva 2D do Lupi. Um cavaleiro, quatro árvores, três pedras e um chão de 15 × 15 unidades. Apenas caminhada, câmera e colisão simples; sem combate, pulo, áudio ou dependências de execução externas.

## Versão 0.3: personagem e renderização

A conversão anterior agrupava vértices em uma grade e removia a cabeça interna ao capacete, o que podia abrir falhas e deixar superfícies sobrepostas visíveis. Agora a malha é simplificada por componente com meshoptimizer, a cabeça é preservada e as faces traseiras são descartadas antes de desenhar. Os membros mantêm grupos separados durante a caminhada.

O renderizador calcula o seno/cosseno dos membros uma vez por quadro e a perspectiva uma vez por vértice. A fila de triângulos é reutilizada com limite de 768 entradas. A biblioteca meshoptimizer está incluída em .tools/vendor/ apenas para a conversão no computador; não é carregada no jogo.

Comparação no harness Lua local, sem medir o console:

| Medida | 0.2 | 0.3 |
| --- | ---: | ---: |
| Máximo de triângulos desenhados no giro central de 360 graus | 1.407 | 382 |
| Memória Lua retida após os testes | ~708 KiB | ~321 KiB |
| Pico observado no teste | ~849 KiB | ~385 KiB |
| Tempo por quadro no computador usado | ~3,1 ms | ~0,9 ms |

Esses números não incluem o motor nem demonstram a taxa de quadros no aparelho. As prévias de diagnóstico foram inspecionadas em oito ângulos e os testes exercitam 128 combinações de orientação e pose de caminhada.

## Carregamento pelo Lupi

`lupi.yaml`, `game.lua` e todos os módulos Lua estão na raiz, conforme os projetos oficiais. A versão é 0.3 e `public: true`. A estrutura anterior em `src/` foi corrigida porque podia impedir a descoberta pelo catálogo. As pastas `.tools/` e `.assets-source/` ficam ocultas para o codec oficial, que ignora entradas iniciadas com ponto. A saída de build também fica fora da lista de fontes, em `.build/`.

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
- Geometria compartilhada por instância: cavaleiro 223 vértices / 374 triângulos; árvore 63 / 105; pedra 16 / 28. Chão: 72 triângulos. Total de entrada da cena: 950 triângulos; triângulos fora da tela e degenerados são descartados antes do desenho.
- Fila reutilizável com teto de 768 triângulos, inclusive recortes no plano próximo. `Game.dropped` detecta estouro.
- Projeção em perspectiva, recorte no plano próximo e ordenação por profundidade média. O chão é desenhado primeiro. A ordenação não substitui um z-buffer: interseções e superfícies próximas podem mostrar artefatos neste protótipo.
- Alvo de projeto: reservar a maior parte dos **4 MiB informados** ao firmware/motor. Os testes de Lua no computador mediram aproximadamente **321 KiB retidos e 385 KiB de pico observado**; não representam a RAM total do aparelho. Framebuffers, runtime, pilhas e demais estruturas do motor também precisam caber na memória real.
- O simulador/código público não fornece aqui uma medição completa do hardware. **Não foi executado no console nem no simulador gráfico nesta máquina. Não há garantia de 60 FPS nem de consumo total abaixo de 4 MiB sem medir nessa versão do aparelho.** A API e a lógica foram verificadas por um harness Lua, e a imagem foi reconstruída das chamadas de desenho.

## Verificar e gerar o pacote

Na raiz do repositório, com Lua 5.4+ e Node.js:

```sh
lua .tools/check.lua
lua .tools/check-models.lua
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
