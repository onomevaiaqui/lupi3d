# Investigação da desaceleração — 13.6

O usuário relatou queda de KM/H, sem perda de vida, inclusive no meio da pista. Foram auditadas as alterações de velocidade em `race.lua` e `combat.lua`, a leitura dos controles e a temporização. As causas abaixo foram reproduzidas localmente; isso não comprova que sejam as únicas causas observadas naquela partida no aparelho.

## Dificuldade

`config.rival_difficulty` multiplica apenas ritmo-alvo e aceleração dos rivais. Não há regra que reduza a potência do jogador por ele liderar ou por outro carro se aproximar. Rivais mais competitivos podem aumentar a frequência de empurrões/ataques, mas não alteram os atributos do jogador.

Os testes mantiveram o jogador na velocidade máxima, segurando acelerador no asfalto e nas zebras das 15 pistas, com o multiplicador em 1,0 e 1,15. Os +15% foram preservados.

## Referência antiga do trecho: asfalto reconhecido como grama

A busca de posição começava nos quatro segmentos anteriores/posteriores à referência do jogador. Nos trajetos sem ponte, só procurava globalmente se a distância encontrada fosse maior que 12 unidades. Nos viadutos, essa recuperação global não acontecia.

Uma referência de outro ramo próximo podia continuar sendo escolhida, embora o carro estivesse sobre o asfalto de outro trecho. A consequência era aplicar o limite de grama sem tirar vida. Foi reproduzido no Viaduto Sul com posição real 16,5 e referência antiga 49: o Fusca caiu de 17,25 para 16,43 unidades/s em 0,125 segundo, ainda marcado como fora da pista e com vida 100.

A correção preserva a busca local rápida, mas permite recuperar segmentos próximos através de células espaciais de 16 unidades quando a referência não é compatível com a área de rodagem. A altura participa da escolha nos viadutos para diferenciar níveis. As buscas sem referência usadas na construção do cenário continuam globais, e o fallback antigo para posições muito afastadas permanece.

Isso evita fazer uma busca completa da pista em todo subpasso da física na grama. No caso reproduzido, o carro passa a permanecer no asfalto e conserva 17,25 unidades/s e vida 100.

## Zebra e tolerância da borda

A zebra visual mede 0,48 unidade para fora do asfalto. Antes, a física só aceitava a meia largura de 6,7 unidades como piso de corrida; um carro no centro da zebra já recebia a penalidade de grama.

A área de rodagem agora inclui a zebra. Há tolerância de 0,25 unidade para entrar no estado de grama e 0,05 para voltar ao piso de corrida, evitando alternância na borda. A grama real continua desacelerando. O corredor usado para validar voltas e detectar cortes de caminho continua separado e não foi ampliado.

## Fim do nitro

O jogador tinha sua velocidade cortada imediatamente para a máxima sem nitro. No Fusca sem upgrades, isso era de 18,975 para 17,25 unidades/s: aproximadamente 114 para 104 km/h no HUD, mesmo no centro do asfalto e com vida intacta.

Agora, quando está acima da máxima normal, a velocidade retorna gradualmente ao limite, com desaceleração de 9 unidades/s² ou a desaceleração de freio se ela for maior. A duração do nitro, o bônus de 10%, a máxima normal e a aceleração dos carros não foram aumentados. Uma nova coleta limpa o aviso de encerramento do nitro anterior.

## Feedback no console

Além dos avisos existentes de grama e corte de caminho, a corrida informa brevemente:

- `ATINGIDO / RECUPERANDO`: houve dano e a recuperação do impacto ainda está sendo indicada;
- `FREIO`: a entrada de freio está ativa;
- `NITRO ENCERRADO`: o bônus terminou;
- `ACELERADOR SOLTO`: o carro está em movimento e a entrada do acelerador está inativa, sem freio ou outro aviso prioritário.

O último aviso permite distinguir falta de leitura de B de uma redução aplicada pela física. Não foi adicionado acelerador automático nem ignorado o freio para mascarar uma eventual falha de controle. Os ataques e sua redução de vida/velocidade continuam funcionando.

## Validação

`lua .tools/check-speed.lua` passou com:

- 47.264 combinações de centro de pista, altura e referência anterior nas 15 pistas, sem retorno fora da área de rodagem;
- velocidade constante no asfalto e nas zebras, com acelerador mantido e os dois multiplicadores de dificuldade;
- recuperação do caso reproduzido no Viaduto Sul;
- fim de nitro sem corte instantâneo nos seis modelos;
- desaceleração legítima por grama e freio, além de dano/aviso de impacto;
- preservação da volta numa excursão pequena e invalidação num corte grande.

Também passaram os testes de cache, malhas/cores, 90 enquadramentos, dificuldade, upgrades, saves, carregador restrito, API 0.6.8, pacote e áudio simulado. O benchmark gráfico continuou com as mesmas contagens de triângulos, vértices e áreas projetadas. Não houve alteração no ícone corrigido de 64 × 32.

O teste decisivo continua no console. Caso a sensação de carro pesado reapareça, registrar o aviso exibido, KM/H antes/depois, pista e situação do nitro ajuda a separar as causas restantes. A correção não foi validada por observação direta da partida que motivou o relato.
