# HUD 14.0 e investigação de velocidade

Velocímetro digital de três dígitos, em KM/H, acompanhado de barra de velocidade. O valor continua derivado da velocidade física real do carro, multiplicada por seis, como nas versões anteriores.

A faixa inferior mantém volta, posição e vida e mostra **TIRO** e **MINA** simultaneamente com suas quantidades. Cinza indica estoque vazio; amarelo e sublinhado indicam o item equipado e disponível. **Y** usa o item selecionado e **R** troca entre os estoques disponíveis. Quando a munição equipada acaba, aparece `Y: SEM ITEM`; use R para equipar outro estoque disponível. Nitro continua automático e aparece como `NITRO +10%` enquanto está ativo.

O novo desenho usa texto e retângulos nativos, sem imagens, fontes novas ou polígonos 3D adicionais.

## Relato de lentidão

O jogador informou que o KM/H cai sem redução de FPS. Isso indica desaceleração na simulação, não comprova um gargalo do renderizador. A revisão das atribuições de velocidade encontrou freio, acelerador solto, grama, teto de velocidade/fim do nitro, dano por armas e limite externo do cenário. Colisão entre carros continua provocando deslocamento, sem desconto direto de velocidade; dificuldade e upgrades rivais não reduzem a velocidade do jogador.

A versão registra e exibe por um curto período a causa efetivamente aplicada: `FREIO`, `ACELERADOR SOLTO`, `FORA DA PISTA`, `LIMITE / FIM DO NITRO`, `ATINGIDO: TIRO`, `ATINGIDO: MINA` ou `LIMITE DO CENARIO`. Avisos de destruição e atalhos têm prioridade. Esses avisos não alteram a física.

Não foi reproduzida desaceleração indevida no centro do asfalto nos testes automatizados; não se considera resolvido o relato no hardware. No próximo teste, observar o aviso quando o KM/H cair, além da vida, do nitro e do estado do acelerador. Isso permite corrigir a causa observada sem remover penalidades válidas por suposição.

Validação: estoques vazios, coleta dos dois itens, seleção, consumo de três tiros e duas minas, nitro, motivos de desaceleração, testes de velocidade nas quinze pistas e equivalência da física com a base anterior (isolando o agendamento de decisões da IA).
