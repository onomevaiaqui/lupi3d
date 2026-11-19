# Curvas dos adversários — 13.7

## Sintoma e diagnóstico

No vídeo enviado, os adversários pareciam pular posições nas curvas. Há também variação visível de FPS, mas o código tinha uma descontinuidade geométrica independente disso.

A posição do centro da pista era interpolada, porém o ângulo retornado por `track.sample` era constante dentro de cada segmento. A IA somava o deslocamento de faixa usando `cos(ângulo)` e `sin(ângulo)`. Ao mudar de segmento, o ângulo mudava instantaneamente, deslocando também a posição lateral do carro. Quanto mais externa a faixa, maior o salto.

Na pista de Santiago, usada no vídeo, uma faixa simulada de 5,5 unidades apresentou salto de aproximadamente **1,623 unidade** e mudança instantânea de cerca de **16,97 graus** em uma junção. O maior caso encontrado nas 15 pistas foi de aproximadamente 4,347 unidades, na pista 4. Esses são testes com amostras imediatamente antes/depois de uma junção; não uma medição extraída dos pixels do vídeo.

## Correção

`track.sampleLane` interpola as normais dos pontos que já definem as bordas da pista. Assim, o fim de um segmento e o começo do próximo coincidem para qualquer faixa, inclusive na passagem pela chegada. A orientação usa interpolação angular pelo caminho mais curto, com dados preparados na construção da pista.

`track.advanceLane` usa o comprimento do trajeto daquela faixa, não somente o comprimento da linha central. Uma faixa externa percorre mais distância na curva que uma interna. Quando o deslocamento de um passo cruza uma junção, a distância restante passa para o segmento seguinte em vez de usar o comprimento antigo para todo o passo.

A posição real do carro segue essa trajetória; não foi adicionada uma imagem intermediária separada da colisão. A IA continua sendo atualizada em cada subpasso da física. Os alvos `aiSpeed`, os +15% de dificuldade, upgrades e velocidade do jogador não foram alterados.

A ordem de chegada e o tempo de volta dos rivais podem mudar: o sistema anterior acrescentava deslocamentos laterais instantâneos e distorcia a velocidade nas faixas curvas. Preservar os parâmetros não significa preservar esse comportamento incorreto.

## Custo

As diferenças de normal e de ângulo são preparadas uma vez por segmento. A posição da IA deixa de chamar seno/cosseno para seu deslocamento lateral em todo passo. O avanço passa a calcular uma raiz quadrada para o comprimento da faixa e a tratar a passagem entre segmentos. Não foram adicionados modelos, polígonos ou objetos de cenário.

No benchmark local de física, a mediana passou de 0,103 para 0,113 segundo para 20 corridas simuladas de dez segundos, 400 passos por corrida, cinco rivais ativos e interface gráfica ausente. É um pequeno custo adicional de física nesse teste; não é uma medição de FPS do console nem garante aumento de fluidez global.

## Testes

`lua .tools/check-ai-motion.lua` verificou:

- 4.120 junções nas 15 pistas e cinco posições laterais, incluindo a chegada;
- continuidade de posição, altura e orientação entre os segmentos;
- equivalência entre avançar 60 unidades de uma vez e em 600 avanços de 0,1;
- movimento real da IA atravessando todas as junções, sem colisões: o deslocamento horizontal não supera o permitido pela velocidade e o progresso avança continuamente.

Com amostras a 0,0000001 segmento de cada lado da junção, o maior deslocamento medido ficou em cerca de 0,000002028 unidade e a maior diferença de ângulo em 0,000000101 radiano, compatíveis com movimento contínuo entre essas duas amostras.

Também passaram os testes de velocidade/grama/nitro da 13.6, dificuldade, upgrades, saves, cache, gráficos, carregador restrito, API 0.6.8, pacote e áudio simulado. As mudanças de colisão por impacto permanecem em funcionamento; esse teste de limite de deslocamento isola a trajetória sem colisões.

## Conferência no console

Confirmar versão **13.7**, observar os rivais nas primeiras curvas de Santiago e repetir com o pelotão junto. O salto ao mudar de segmento deve desaparecer; FPS baixo ainda pode tornar o movimento pouco fluido. Se restarem saltos, distinguir se ocorrem junto de uma batida, passagem de viaduto ou queda do contador de FPS ajuda a investigar a próxima causa.
