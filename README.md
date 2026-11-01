# Lupi Pista 8 3D — Fusquinha (3.0)

Corrida em 3D poligonal para testar o Lupi: pista em oito de aproximadamente 227 unidades, um Fusquinha amarelo, um adversário vermelho, oito árvores e chegada quadriculada. A pista anterior tinha aproximadamente 146 unidades. Complete três voltas seguindo a direção inicial. O cruzamento é plano, sem ponte.

| Controle SNES | Ação |
| --- | --- |
| B | Acelerar |
| A | Frear |
| Esquerda / direita | Esterçar |
| Y | Reiniciar corrida e semáforo |

O semáforo da interface passa por vermelho (2 s), amarelo (1 s) e verde. Antes do verde, os dois carros e o cronômetro ficam parados. Segurar B durante a contagem permite acelerar assim que a corrida é liberada. Y funciona também após a chegada e dispara uma vez por aperto.

O padrão é `controller="snes"`: B=`BTN_Z`, A=`BTN_G`, Y=`BTN_F`. A pedido do usuário, Y substitui Start. No modo direto do simulador, `controller="lupinho"`, usa BTN_Z/BTN_X/BTN_Q respectivamente. As cores mantêm BGR555; `platform="hardware"` troca vermelho/azul.

## Corrida

Aceleração, freio, arrasto e direção dependem do tempo e da velocidade. A tem prioridade sobre B; não há marcha a ré. A grama desacelera. Quatro setores em sequência validam cada volta. A busca do trecho mais próximo considera o progresso anterior, distinguindo os dois ramos do cruzamento. A primeira passagem na linha inicia a contagem de voltas. A prova termina quando o jogador completa três voltas.

O adversário percorre a mesma linha central a 10,5 unidades/s; o jogador chega a 15. O HUD mostra a posição relativa no percurso. Nesta versão os carros podem atravessar um ao outro; as árvores são decorativas e não têm colisão.

## 3D e desempenho

Carros, asfalto, zebras, chegada e árvores são malhas XYZ com perspectiva e rasterização por `ui.trisfill`. O semáforo e os indicadores são interface 2D. O fundo plano da grama é preenchido por um retângulo até o horizonte fixo da câmera traseira, evitando dois triângulos enormes de terreno. A pista permanece em 3D poligonal.

O renderizador conserva recorte próximo/na tela, descarte de faces traseiras, validação de triângulos inteiros e ordenação por profundidade média. Não há z-buffer, texturas ou luzes dinâmicas. Foram adicionados descarte de objetos antes de projetar os vértices e distância de desenho de 30 unidades. As zebras aparecem até 20 unidades. Árvores e trechos distantes podem surgir/desaparecer no limite de visão.

| Elemento | Triângulos de malha |
| --- | ---: |
| Fusquinha do jogador | 76 |
| Adversário | 32 |
| Pista e zebras | 272 |
| Chegada | 16 |
| Oito árvores | 64 |
| Total armazenado | 460 |

Embora a cena tenha mais elementos, não desenha toda a malha em cada quadro. O carro anterior tinha 176 triângulos; faces escondidas, para-lamas e para-choques separados foram simplificados. Nos 288 pontos/ângulos de teste, com o adversário próximo, o pico caiu de 227 para 158 triângulos enviados por quadro (cerca de 30% menos). A largada envia 104, contra 157 no oval. O contador TRI mostra o valor efetivo.

Tela de 480 x 270, paleta de 32 cores, pool de 384 triângulos reutilizados. Pacote de oito módulos Lua com aproximadamente 21 KB. Heap Lua do harness em torno de 401 KiB, sem incluir motor, framebuffer e sistema. O teste em computador não comprova consumo total nos 4 MB nem FPS no aparelho.

O oval 2.1 rodou a 14–16 FPS segundo o usuário. A meta desta revisão é 24 FPS, mas ainda não foi medida no Lupi e não há garantia desse resultado.

## Executar e verificar

`lupi.yaml` e `game.lua` permanecem na raiz. O cabeçalho deve mostrar **PISTA 8 3D 3.0 / FUSQUINHA**.

```sh
lua .tools/check-renderer.lua
lua .tools/check.lua
node .tools/build.cjs
node .tools/check-discovery.cjs
lua .tools/check-release.lua
```

O build fica em `.build/race-3d-release/`, com os oito módulos e manifesto; não inclui o motor. Não requer imagens nem processamento de assets.

Os testes verificam controles e HUD fracionário em diferentes FPS, grama, ramo correto no cruzamento, sequência dos checkpoints, três voltas completas dirigidas com os comandos do jogo, movimento do adversário, bloqueio durante o semáforo, reinício por Y, posição das árvores fora da pista e 288 vistas sem estouro do pool.

Prévia no Windows após `check.lua`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1
lua .tools/overview.lua
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1 -Frame view-overview
```

A vista superior projeta as próprias malhas XYZ para verificar o formato em oito. O oval anterior permanece no [commit 8f352d7](https://github.com/onomevaiaqui/lupi3d/tree/8f352d7a19667dc990f83974a27059b99b368019).
