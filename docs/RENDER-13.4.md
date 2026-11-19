# Renderização otimizada — 13.4

## Escopo

Esta versão implementa otimizações possíveis no jogo distribuído pelo catálogo, sem acesso ao firmware especial da demonstração enviada pelo usuário. Modelos continuam como malhas XYZ em Lua, e o desenho continua usando a API pública `ui.trisfill`. Não há modelos embutidos na flash, nova API nativa ou redução de qualidade para obter o resultado.

A referência é a versão 13.3, commit `bf07ebf`. Foram preservados os seis carros, suas contagens de polígonos, os cenários, a paleta de 36 cores, a câmera, a distância de visão, o pool, a dificuldade, controles, física, combate, saves e ícone.

## Alterações

### Transformações do cenário estático

`renderer.prepare(obj, camera)` prepara posições locais dos vértices já rotacionadas pela orientação do objeto e da câmera. A cada quadro, o caminho preparado precisa aplicar somente a translação relativa, perspectiva e etapas de desenho. A translação é reaproveitada da verificação de visibilidade do objeto.

Pista, zebras, marcações, chegada, grid, decoração, árvores nos dois níveis de detalhe e caixas de itens são preparados ao iniciar a corrida. Isso evita construir os caches quando os objetos entram na tela. Os objetos mantêm a geometria XYZ original; não são imagens pré-renderizadas.

Os dados pertencem aos objetos da corrida. Não há um catálogo global de pistas antigas mantendo esses caches vivos. Cada árvore guarda os dois modelos de ALTO/LEVE. Mudanças de malha, rotação do objeto ou orientação da câmera invalidam/revalidam os dados corretamente. Mover um objeto não exige recalcular seus vértices locais. As malhas preparadas são tratadas como imutáveis: alterar o conteúdo de seus vértices em lugar exige descartar/repreparar seus caches.

### Carros e demais objetos móveis

A rotação do objeto é combinada com a orientação da câmera uma vez por objeto. A translação também sai do laço de vértices. O índice do vértice passa a ser incrementado, em vez de recalculado por uma divisão em cada iteração.

Os carros continuam atualizando sua orientação livremente. Não há quantização de ângulos, remoção de faces ou quadros de animação pulados.

### Recorte e chamadas de desenho

O recorte continua protegendo a região de jogo e o plano próximo. O algoritmo deixa de atravessar bordas que já contêm todos os vértices do triângulo original; recortar por outras bordas não pode criar pontos fora dessas bordas já satisfeitas.

`ui.trisfill` e a tabela de índices de cor são consultados uma vez por lote de desenho. Funções auxiliares de estrada e objetos passam a ser funções do módulo, eliminando as três/quatro closures recriadas por quadro na implementação anterior. Seno/cosseno da câmera só são recalculados quando sua orientação muda.

## Resultado local

Benchmark com a mesma semente, 45 cenas nas 15 pistas e seis carros nos enquadramentos de grupo. O tempo corresponde à mediana de três lotes de 1.800 desenhos da largada de Santiago, no mesmo PC com interface simulada:

| Medida | 13.3 | 13.4 |
| --- | --- | --- |
| Triângulos desenhados nas 45 cenas | 14.674 | 14.674 |
| Vértices projetados nas 45 cenas | 27.801 | 27.801 |
| Soma estimada das áreas projetadas, pixels² | 2.198.511 | 2.198.511 |
| Falta de espaço no pool | 0 | 0 |
| Mediana do desenho, medição comparativa final | 1,289 s | 1,170 s |

Essa medição corresponde a aproximadamente **9,2% menos tempo de desenho**. Outras rodadas locais ficaram próximas de 10%. Não é FPS do hardware, não inclui o custo real do rasterizador/transporte do console e não permite prometer 60 FPS.

Na largada de Santiago, 291 dos 878 vértices projetados usaram o caminho preparado, sem reconstrução de cache durante o desenho. A aceleração dos objetos móveis também participa do resultado; o cache estático isolado não tinha apresentado ganho convincente no primeiro protótipo.

### Memória

Teste com três passagens pelas 15 pistas, ambos os modos de detalhe e coleta de lixo explícita:

| Memória Lua viva após coleta, no PC | 13.3 | 13.4 |
| --- | --- | --- |
| Maior valor observado | 881,3 KiB | 1.050,1 KiB |
| Santiago após passagens sucessivas | 788,6 / 790,3 / 790,3 KiB | 917,0 / 917,0 / 917,0 KiB |

O custo adicional observado no maior caso é aproximadamente **169 KiB**. Os caches da pista anterior foram recuperáveis e os valores estabilizaram. Esses números não representam a memória total do console, nem o pico antes da coleta: faltam framebuffer, firmware, áudio e outros recursos nativos. Os tamanhos de objetos Lua também podem diferir entre o PC e o firmware.

## Qualidade e funcionamento

Foram comparadas 120 cenas de corrida cobrindo todas as pistas, ALTO/LEVE, largada, grupos, viadutos e efeitos, mais sete telas de menu/seleção/resultado/pódio. Das 127 saídas, 124 tiveram comandos geométricos idênticos. Três tiveram diferenças na ordem de comandos, mas a rasterização de teste não encontrou pixels diferentes. Isso é uma verificação por software, não uma captura do framebuffer do aparelho.

Também passaram:

- comparação exata dos estados de física e combate em 15 corridas determinísticas de oito segundos com seis carros;
- pré-aquecimento dos caches em todas as pistas e ambos os modos, reutilização por translação e invalidação por rotação, câmera ou malha;
- limites de objetos, polígonos e cores, além de 90 enquadramentos de stress;
- simulação da API 0.6.8, carregador restrito, dificuldade, upgrades, saves, áudio simulado, manifesto e ícone.

## Repetir os testes

Na raiz do repositório:

```sh
node .tools/build.cjs
node .tools/check-discovery.cjs
lua .tools/check-render-cache.lua
lua .tools/check-visuals.lua
lua .tools/benchmark-visuals.lua
```

Para comparar uma cópia dos módulos da 13.3 em `.build/render-baseline-13-3`:

```sh
lua .tools/benchmark-visuals.lua .build/render-baseline-13-3
lua .tools/capture-render.lua .build/render-baseline-13-3 before
lua .tools/capture-render.lua . after
node .tools/compare-render.cjs
lua .tools/check-render-physics.lua .build/render-baseline-13-3
```

`config.cache_static_geometry=false` permite desativar apenas o cache para diagnóstico; a projeção combinada e as demais otimizações continuam ativas. Os scripts de comparação usam saves separados e não gravam progresso normal.

## Teste no Lupi

1. Confirmar **13.4** no menu.
2. Usar a mesma pista, carro e modo gráfico usados na 13.3.
3. Comparar o FPS da largada com seis carros, do grupo andando e do jogador isolado.
4. Conferir os viadutos, alternar ALTO/LEVE e reiniciar/trocar pistas para verificar estabilidade.

O objetivo deste teste é medir quanto das otimizações de Lua se transfere ao aparelho. A demonstração com modelo na flash pode usar um caminho nativo diferente; reproduzir seu desempenho exige o código ou uma API de firmware correspondente, ainda não disponíveis neste trabalho.
