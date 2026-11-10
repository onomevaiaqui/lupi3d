# Dificuldade e veículos — 13.2

## Objetivo

Aumentar o desafio inicial e fazer os rivais evoluírem ao longo de Chile, Paraguai, Argentina e Brasil, preservando o benefício das peças compradas. O ritmo é definido na criação da corrida. Não há multiplicador baseado na distância do jogador, teletransporte ou ajuste de dificuldade durante a prova.

## Upgrades dos rivais

Cada nível comprado de motor, pneus ou blindagem seleciona um ou dois adversários distintos para receber um nível da mesma peça. Cada peça continua limitada ao nível 3. A escolha usa uma sequência pseudoaleatória derivada do nome do jogador, categoria da peça e nível comprado. Isso evita aumentar o formato do save e mantém a distribuição depois de reiniciar ou carregar Continue. Com o mesmo nome e os mesmos níveis, a distribuição é a mesma; não depende da ordem das compras. Desde a versão 13.2, o sorteio considera apenas rivais com espaço para melhorar a peça, removendo o primeiro escolhido antes de selecionar um segundo. Uma peça no máximo não desperdiça a distribuição. As escolhas continuam estáveis e não são refeitas a cada corrida.

Na Argentina e no Brasil, os cinco rivais também têm um nível básico de cada peça. Esses níveis se somam às compras reconstruídas, até o limite 3. Repetir uma corrida, receber dinheiro ou comprar uma peça que já está no máximo não cria novos níveis.

| Peça | Efeito por nível |
| --- | --- |
| Motor | +12% de aceleração e +5% de velocidade máxima |
| Pneus | Jogador: +10% de direção e +8% de velocidade na grama. IA: melhora os mesmos atributos do carro e aumenta a resposta de retorno à faixa de 0,6 para até 0,96 |
| Blindagem | +20 de vida máxima, também restaurada no respawn |

Os upgrades do jogador não foram reduzidos. A IA ainda segue o percurso paramétrico e não usa a mesma direção manual do jogador; a resposta à faixa é o efeito operacional dos pneus na sua movimentação.

## Ritmo e combate

O estágio é `país - 1`, com um acréscimo gradual de até 0,45 dentro dos países de quatro pistas, ou 0,4 no Brasil. Na partida, cada rival recebe uma das cinco formas de pilotagem: 0,92; 0,96; 1,00; 1,03; 1,06, embaralhadas por corrida.

O alvo de velocidade é calculado uma vez:

```text
velocidade do modelo com motor × (0,73 + estágio × 0,055) × forma × ritmo global × 1,15
```

A versão 13.2 acrescenta 15% ao ritmo-alvo e à aceleração dos rivais, através de `config.rival_difficulty=1.15`. Esse percentual é relativo à versão 13.1 e não é uma medição da probabilidade de vitória. A física do jogador permanece igual. A IA segue um percurso paramétrico e seu ritmo não corresponde ao limitador usado pelo controle manual do jogador.

O fator de campanha começa em 0,73 e chega a 0,917 na última pista do Brasil, antes da forma individual e do motor. Nitro mantém o bônus de 10%. Os rivais aceleram gradualmente usando o motor, em vez de saltarem imediatamente para sua velocidade de cruzeiro. Stun e dano continuam afetando-os.

O combate continua limitado a quatro avaliações por segundo por adversário, com avaliações iniciais escalonadas. A chance de agir quando há uma oportunidade sobe de 65% para até 95% ao longo da campanha. Para tiros, a IA passa a verificar alinhamento lateral e altura do alvo antes de gastar munição. Não há munição infinita ou aumento de dano das armas.

O embaralhamento da forma mantém variação entre provas. Não garante uma ordem diferente em toda corrida: modelos, upgrades, coletas e colisões também influenciam o resultado.

## Novos veículos

| Modelo | Velocidade base | Aceleração | Direção | Grama | Vida base | Triângulos |
| --- | --- | --- | --- | --- | --- | --- |
| Chevette | 15,4 | 7,8 | 1,48 | 5 | 100 | 106 |
| Kombi | 13,5 | 6,7 | 1,42 | 5,8 | 120 | 158 |

São unidades internas antes de aplicar ritmo e upgrades. O Chevette tem silhueta de sedã com capô, cabine e porta-malas separados. A Kombi foi refeita na versão 13.1 seguindo uma referência da versão antiga: frente inclinada com V, teto claro com bordas chanfradas, para-brisa dividido, janelas separadas, faróis facetados e calotas claras. As superfícies de vidro, faróis e calotas são encaixadas na malha, sem sobrepor painéis grandes, para evitar cortes no renderizador por ordenação de profundidade. A Kombi passou de 90 para 158 triângulos para representar esses detalhes; os demais carros mantêm a contagem anterior. Ambas usam a paleta existente. O para-brisa frontal do construtor compartilhado teve a orientação das faces corrigida, sem aumentar sua contagem de triângulos.

Os IDs 1–4 dos carros anteriores foram mantidos; Chevette e Kombi usam 5 e 6. O save atual aceita os seis IDs e continua lendo os formatos antigos. Há seis carros na corrida, não oito.

## Referências e escolhas

- [An Architecture Overview for AI in Racing Games — Simon Tomlinson e Nic Melder, Game AI Pro](https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter38_An_Architecture_Overview_for_AI_in_Racing_Games.pdf): descreve a separação entre habilidade do piloto, desempenho do carro e decisões de corrida, inclusive para uma IA simplificada que segue curvas paramétricas. É a base conceitual da variação de forma e dos atributos dos carros.
- [A Rubber-Banding System for Gameplay and Race Management — Nic Melder, Game AI Pro](https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter42_A_Rubber-Banding_System_for_Gameplay_and_Race_Management.pdf): discute ajustes de potência/habilidade conforme a distância e os problemas de percepção de injustiça. Neste projeto, optamos por definir a evolução entre provas, preservando diferenças de equipamento durante a corrida.

Os multiplicadores, preços, chances e regras de compra acima são escolhas de equilíbrio deste jogo; não são valores prescritos pelas referências.

## Validação e limites

`lua .tools/check-difficulty.lua` verifica malhas e cores dos seis modelos, 360 eventos de compra, estabilidade da distribuição, crescimento de ritmo nas 15 pistas, efeitos dos upgrades, simulações com seis carros, gravação/leitura dos seis modelos e leitura de um save antigo. Antes de executar, crie `.build/difficulty-test`; os saves de teste ficam nessa pasta, separados do progresso normal.

As decisões de compra são calculadas na criação da prova. Não foram acrescentadas buscas de caminho nem novas decisões por quadro. Os testes locais não medem o FPS do hardware nem garantem um nível de dificuldade ideal para todos: a calibragem final precisa de corridas no console, especialmente com a Kombi e nos últimos países.
