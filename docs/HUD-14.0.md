# HUD 14.0 e investigação de velocidade

Velocímetro digital de três dígitos, em KM/H, acompanhado de barra de velocidade. O valor continua derivado da velocidade física real do carro, multiplicada por seis, como nas versões anteriores.

A faixa inferior mantém volta, posição e vida e mostra **TIRO** e **MINA** simultaneamente com suas quantidades. Cinza indica estoque vazio; amarelo e sublinhado indicam o item equipado e disponível. **Y** usa o item selecionado e **R** troca entre os estoques disponíveis. Quando a munição equipada acaba, aparece `Y: SEM ITEM`; use R para equipar outro estoque disponível. Nitro continua automático e aparece como `NITRO +10%` enquanto está ativo.

O novo desenho usa texto e retângulos nativos, sem imagens, fontes novas ou polígonos 3D adicionais.

## Relato de lentidão

O jogador informou que o KM/H cai sem redução de FPS. Isso indica desaceleração na simulação, não comprova um gargalo do renderizador. A revisão das atribuições de velocidade encontrou freio, acelerador solto, grama, teto de velocidade/fim do nitro, dano por armas e limite externo do cenário. Colisão entre carros continua provocando deslocamento, sem desconto direto de velocidade; dificuldade e upgrades rivais não reduzem a velocidade do jogador.

A versão registra e exibe por um curto período a causa efetivamente aplicada: `FREIO`, `ACELERADOR SOLTO`, `FORA DA PISTA`, `LIMITE / FIM DO NITRO`, `ATINGIDO: TIRO`, `ATINGIDO: MINA` ou `LIMITE DO CENARIO`. Avisos de destruição e atalhos têm prioridade. Esses avisos não alteram a física.

Não foi reproduzida desaceleração indevida no centro do asfalto nos testes automatizados; não se considera resolvido o relato no hardware. No próximo teste, observar o aviso quando o KM/H cair, além da vida, do nitro e do estado do acelerador. Isso permite corrigir a causa observada sem remover penalidades válidas por suposição.

Validação: estoques vazios, coleta dos dois itens, seleção, consumo de três tiros e duas minas, nitro, motivos de desaceleração, testes de velocidade nas quinze pistas e equivalência da física com a base anterior (isolando o agendamento de decisões da IA).

## Prévia 14.1

HUD minimalista inspirada em art of rally: volta atual no alto à esquerda, velocidade no canto inferior direito, ícones de tiro e mina com quantidades no inferior esquerdo. Posição e vida aparecem discretamente no alto à direita. Não há painéis, faixas opacas, cronômetro ou barra de velocidade. Amarelo e um pequeno sublinhado identificam o item selecionado; R troca e Y usa. A volta mostrada é a volta em curso, começando em 1/N, preservando o contador interno de voltas concluídas.

Os algarismos de velocidade são sólidos e levemente inclinados, preparados em retângulos uma vez ao carregar. Texto e ícones têm sombra de um pixel para contraste sem caixas de fundo. A renderização 3D passa a alcançar as bordas 0..269 da tela, em vez de reservar as antigas faixas de HUD. Não altera câmera, malhas ou física, mas o aumento da área visível pode exigir mais rasterização; FPS real precisa ser validado no console. As quinze pistas passaram pelas 90 vistas de teste sem descarte de triângulos.

Referências consultadas: [Horizon Chase 2, página do desenvolvedor na App Store](https://apps.apple.com/us/app/horizon-chase-2/id1534920947?platform=tv), [art of rally, site oficial e galeria](https://www.artofrally.com/) e [Forza Horizon 5, opções de acessibilidade visual](https://support.forza.net/hc/en-us/articles/4409280058259-Forza-Horizon-5-Accessibility-Support). São referências de direção visual e legibilidade, sem reutilizar os assets desses jogos.

A referência foi aplicada à HUD, sem reproduzir cenário, minimapa ou efeitos gráficos de outros jogos. A prévia local usa uma fonte substituta para os textos comuns; os algarismos de velocidade vêm dos retângulos reais do jogo. Esta versão permanece local para avaliação visual antes de publicar.
