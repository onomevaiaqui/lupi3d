# Revisão visual — 13.3

## Cores e iluminação fixa

A paleta mantém os 32 índices anteriores, com cores revistas, e acrescenta quatro materiais de terreno e vegetação nos índices 32–35. Agora há **36 cores**, abaixo dos 256 índices documentados pelo Lupi. A diferenciação evita que as faces claras das árvores se confundam com o chão.

Asfalto e vidro usam tons neutros escuros; pinturas, sinalização e detalhes metálicos têm contraste maior. As faces secundárias passam de fator 0,78 para 0,84, suavizando o escurecimento. Não há luz dinâmica, sombra projetada, textura ou cálculo adicional de iluminação por triângulo. A paleta continua sendo registrada a cada desenho.

## Acabamento dos seis carros

Foram revistas as cores dos vidros inclinados, que antes podiam aparecer azuis, e o contraste dos detalhes das rodas. O Chevette recebe pintura creme e teto claro; o Gurgel recebe teto e para-choque claros. Fusca, Fiat 147, Puma e Kombi aproveitam a nova paleta e os vidros escuros.

Nenhum carro ganhou ou perdeu triângulos ou mudou sua geometria, dimensões de colisão ou atributos:

| Modelo | Triângulos |
| --- | --- |
| Fusca | 82 |
| Fiat 147 | 92 |
| Gurgel X-12 | 104 |
| Puma GTB | 110 |
| Chevette | 106 |
| Kombi | 158 |

## Leitura da pista

- Asfalto uniforme e mais escuro, eliminando a alternância forte de blocos de cor.
- Zebras consistentes em vermelho e branco, com largura de 0,48 em vez de 0,28 unidade. A superfície de rodagem continua com a mesma largura.
- As duas linhas tracejadas que delimitam três faixas ficam mais largas e longas: meia largura 0,095 e meia extensão até 1,35 unidade, em vez de 0,07 e 1.
- Esses ajustes reaproveitam as faces das zebras e das marcações. Percurso, pontes, checkpoints, voltas e linha de chegada não foram alterados.

## Identidade dos países

| País | Materiais e vegetação |
| --- | --- |
| Chile | Areia e terra quente nas regiões secas, pedras no Atacama, pinheiros nas pistas verdes; paredes e cercas em tons de madeira/terra |
| Paraguai | Chão verde, copas largas, casas claras com telhado vermelho; Chaco mais seco e pedregoso |
| Argentina | Pampas com grama seca, vegetação mais baixa, cercas claras, telhados claros e pedras nos Andes |
| Brasil | Verde separado da copa das árvores; coqueiros mais presentes no Rio, copas largas em São Paulo e floresta mista em Foz; casas com cores quentes |

Os materiais regionais das casas, pedras e cercas compartilham as posições dos vértices das malhas já soldadas. Somente as tabelas de cores das faces são diferentes. Coqueiros e árvores de copa larga têm 16 triângulos no modo ALTO e 12 no LEVE. A vegetação baixa da Argentina usa a mesma topologia da copa larga, com proporções menores. Os pinheiros completos têm 20 triângulos; a árvore simples, 12.

Os troncos antigos tinham somente duas faces e desapareciam de alguns ângulos. Foram fechados com quatro faces laterais. Esse pequeno acréscimo na vegetação é compensado, no conjunto medido, pela composição mais econômica e pelas substituições de objetos. Os modelos dos carros não foram simplificados.

## Composição

A posição da decoração prioriza pequenos grupos nas curvas e na aproximação da chegada, alternando os lados das retas. A curvatura é consultada apenas na construção da pista para escolher o lado externo das curvas. O código verifica a distância da pista antes de posicionar objetos e vegetação, inclusive perto de outros ramos dos cruzamentos.

O limite anterior de objetos decorativos foi preservado por pista: no máximo 12, ou os limites menores já existentes nas pistas 2, 4, 6 e 8. Continuam existindo até seis posições de vegetação. Os monumentos passam de até três repetições para até duas. Não foram adicionados grandes conjuntos de arquibancadas, nem aumentada a distância de visão.

## Validação

`lua .tools/check-visuals.lua` verifica paleta, índices e malhas válidos, orçamento original dos carros, limites de objetos, distância dos objetos em relação à pista e 90 enquadramentos com seis carros nos modos ALTO e LEVE. Não houve descarte por falta de espaço no pool de triângulos.

Também passaram os testes de dificuldade/upgrades/saves, carregador restrito, API 0.6.8, pacote publicado e áudio simulado. O `icon.gif` de 128 × 64 permanece idêntico ao já validado no console.

Uma comparação determinística da física e do combate em 15 corridas de oito segundos, com seis carros, produziu exatamente os mesmos estados amostrados da versão 13.2. Ela usa a mesma semente e as mesmas entradas para conferir posições, velocidade, vida, munição, nitro, voltas e progresso.

## Custo comparado com a versão 13.2

O benchmark local avalia três enquadramentos por pista: largada, grupo de seis carros e jogador isolado. São 45 vistas, sempre com a mesma semente. O tempo é a mediana de três lotes de 1.800 desenhos da largada de Santiago, no PC, com chamadas de interface simuladas.

| Medida | 13.2 | 13.3 |
| --- | --- | --- |
| Triângulos desenhados, soma das 45 vistas | 14.929 | 14.674 |
| Vértices projetados, soma das 45 vistas | 28.419 | 27.801 |
| Soma estimada de áreas dos triângulos, pixels² | 2.161.491 | 2.198.511 |
| Maior contagem por vista, somando os lotes de desenho | 531 | 530 |
| Triângulos descartados por falta de pool | 0 | 0 |
| Mediana do tempo local de desenho | aproximadamente 1,3 s | aproximadamente 1,3 s |

Isso representa cerca de 1,7% menos triângulos e 2,2% menos vértices no conjunto, com aproximadamente 1,7% mais área projetada. A redução não acontece em todos os enquadramentos: a nova posição dos objetos pode aumentar a carga de uma vista específica. O tempo local ficou praticamente igual, e não demonstra ganho de FPS no hardware. A soma de áreas inclui sobreposição, não é uma medição de pixels efetivamente processados pelo console. Uma contagem por vista acima de 512 é possível porque o pool é liberado entre lotes dentro do mesmo quadro.

Para repetir o benchmark atual:

```sh
lua .tools/benchmark-visuals.lua
```

O script aceita como argumento um diretório com os módulos de uma versão anterior. Ele usa uma pasta de save separada e não grava progresso. A comparação deve ser feita no mesmo computador e ambiente. O teste decisivo continua sendo no Lupi, especialmente na largada com seis carros, nos viadutos e perto dos monumentos.
