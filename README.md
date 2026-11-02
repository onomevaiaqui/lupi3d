# Lupi Combat Rally 3D — experimento de estádio 6.0

Versão experimental para testar o limite visual do Lupi, inspirada na referência de estádio enviada pelo usuário. Mantém o campeonato, quatro carros, power-ups, áudio, menu e save, mas aumenta bastante a geometria do cenário.

## Ponto de retorno

A versão anterior, validada pelo usuário em aproximadamente **11–14 FPS**, está preservada na tag [v5.1-baseline](https://github.com/onomevaiaqui/lupi3d/tree/v5.1-baseline), commit 73f02354dc20a6fa1e5f86fcf3f299339e7bf1fa. O pacote v5.1 também permanece nos entregáveis da conversa. Se o experimento não funcionar bem, essa é a referência para restaurar o projeto; a reversão deve virar um novo commit/versionamento para o catálogo atualizar corretamente.

**Não há promessa de manter o FPS anterior.** Esta revisão é deliberadamente mais pesada. L alterna o detalhe sem reiniciar, mas LEVE não é uma cópia exata da 5.1: a pista 8 agora possui altura real em ambos os modos. Para retornar exatamente ao cenário anterior, use o ponto de retorno.

## O que mudou

- Duas arquibancadas com degraus, bancos coloridos e painéis quadriculados em cada pista.
- Barreiras baixas claras, pilhas de pneus, borda de concreto e grupos adicionais de árvores de copa facetada.
- Asfalto e zebras subdivididos para curvas visualmente mais suaves no modo ALTO. A rota/checkpoints continuam em 40/48 trechos; a subdivisão visual não muda sua numeração.
- Viaduto verdadeiro na pista Cruzamento 8: rampa suave, tabuleiro e pilares. O cruzamento superior chega a **2,6 unidades** de altura.
- Carros, pickups, minas, rastros e explosões acompanham a altura correspondente. Tiros e minas não atingem carros no outro nível apenas por coincidirem em X/Z.
- Largada/chegada da pista 8 deslocadas para fora de baixo da ponte, mantendo as três voltas e os checkpoints relativos à nova largada.
- Câmera que acompanha o jogador mantida; **X alterna uma vista geral de inspeção do estádio**. A vista geral é ainda mais pesada e não é a opção indicada para buscar FPS alto.
- Sem sombras projetadas sob os carros. As diferenças de cor entre faces são fixas; não há luz ou sombra dinâmica.

As curvas do modo LEVE usam as superfícies mais simples. ALTO acrescenta subdivisão, arquibancadas, barreiras, pneus, árvores agrupadas, construções e detalhes. As barreiras, pilares, pneus e arquibancadas são visuais, sem física de colisão. A grama desacelera o jogador. Os carros ainda podem se atravessar.

As referências foram usadas apenas como orientação visual. As malhas foram criadas em código; nenhuma imagem, marca d'água, textura ou modelo da foto foi copiado.

## Custo medido localmente

| Situação | Triângulos enviados por quadro |
| --- | ---: |
| Pico em 576 vistas, ALTO, câmera normal | 583 |
| Pico nas mesmas vistas, LEVE | 212 |
| Vista geral de inspeção, exemplo | cerca de 1.230 |
| Teste com todos os efeitos ativos, câmera normal na largada | 399 |

Não houve estouro do pool. O limite de triângulos pendentes por passagem subiu para 1.536, reutilizados entre quadros; isso não significa que todos são desenhados em toda vista.

Em um processo de teste limpo, mantendo apenas a corrida atual, o heap Lua ficou em aproximadamente **1,1–1,3 MiB** após várias vistas e a câmera geral. Não inclui motor, sistema, framebuffer ou áudio nativo. Não comprova o consumo total dentro dos 4 MB. O harness funcional mais pesado mantém várias corridas/CSV simultaneamente e não representa a memória da execução normal.

O renderizador continua sem z-buffer, ordenando por profundidade média. O tráfego sobre a ponte usa uma passagem de desenho própria para evitar que o tabuleiro encubra seu próprio carro. Ainda podem ocorrer artefatos de ordenação em interseções ou objetos que se sobrepõem. As vistas são inteiramente projetadas a partir de malhas XYZ, com recorte e validação dos triângulos inteiros antes de ui.trisfill.

## Controles

| SNES | Ação |
| --- | --- |
| Cruz no menu | Escolher opção/pista |
| B no menu | Confirmar |
| X no menu | Testar som |
| B na corrida | Acelerar |
| A na corrida | Frear |
| Cruz esquerda/direita | Esterçar |
| R | Usar uma carga da arma equipada |
| Y na corrida | Reiniciar pista e semáforo |
| Y na seleção/resultado | Menu |
| L na corrida | Alternar ALTO/LEVE |
| X na corrida | Alternar câmera de acompanhamento/vista geral |

Perfil SNES padrão: B=BTN_Z, A=BTN_G, R=BTN_E, Y=BTN_F, L=BTN_Q, X=BTN_X. No modo direto lupinho: BTN_Z/BTN_X/BTN_G/BTN_Q/BTN_F/BTN_E. No menu, Novo Jogo apaga o progresso salvo; Continue libera após uma pista vencida em primeiro lugar.

## Campeonato e itens

Três pistas selecionáveis: Vale Oval (~165 unidades), Cruzamento 8 (~227) e Serra Verde (~180). Cada uma tem três voltas, jogador e três adversários. Vermelho por dois segundos, amarelo por um e verde para liberar carros/cronômetro. Checkpoints em ordem evitam contar voltas de ré.

Vença duas pistas diferentes em primeiro lugar para conquistar o campeonato. Repetir uma vitória na mesma pista não aumenta esse total. O resultado salva a melhor colocação; Continue fica disponível após a primeira vitória. O formato do save anterior é mantido.

- Amarelo: três tiros frontais; alcance 15, dano 35.
- Vermelho: duas minas; dano 50, arma em 0,5 s, dura até 18 s.
- Azul: nitro automático por cinco segundos; aceleração e velocidade máxima +10%.

Tiro/mina substituem a arma atual; nitro coexiste. Caixas retornam após nove segundos. Minas podem atingir o próprio dono. Vida 100; destruído, o carro fica parado por dois segundos, perde itens e retorna no mesmo progresso com vida cheia. Pools limitados a oito minas, quatro rastros e quatro explosões.

## Áudio e save

Áudio preservado da 5.1. Prefere music.loop com os 18 arquivos Furnace originais em music/*.fur, seguindo o [Caio Pernocas](https://github.com/lupi-org-br/caio-pernocas/blob/main/soundtrack.lua). O backend é um fluxo: efeitos curtos interrompem o tema/motor e depois o restauram. Há fallback legado sfx.fx. O menu mostra FUR/SFX/SEM API ou erro; X testa o som. Os módulos foram validados por renderização não silenciosa no Furnace, mas som, entrega dos assets e volume ainda dependem do firmware do console.

Save alternado em rally-save-0.dat e rally-save-1.dat, com geração e checksum, ao terminar cada pista. PROGRESSO SALVO confirma escrita e releitura; SAVE INDISPONIVEL mantém apenas a sessão. Usa io.open quando disponível; package é opcional. Remover os dados do app remove os saves. Y não apaga vitórias.

## Build e verificação

Tela 480x270, 32 cores, BGR555 preservado. Pacote com 14 módulos Lua e 18 arquivos Furnace, aproximadamente 61 KB. Só a pista selecionada é construída. Dados estáticos e malhas repetidas são compartilhados.

```sh
lua .tools/check.lua
lua .tools/check-memory.lua
lua .tools/check-renderer.lua
lua .tools/check-save.lua
lua .tools/check-audio-api.lua
node .tools/build.cjs
node .tools/check-discovery.cjs
lua .tools/check-release.lua
lua .tools/check-firmware.lua
```

Os testes cobrem três corridas completas, checkpoints e alturas no viaduto, armas entre níveis, semáforo, menu, Continue, save, controles L/X e 576 vistas sem triângulos inválidos/estouro. check-memory roda em processo limpo, sem acumular corridas/CSV de teste, e também inspeciona a vista geral de cada pista.

Build em .build/race-3d-release/. Cabeçalho da versão: **LUPI COMBAT RALLY 6.0**. Os .fur são preservados no pacote; o codec público antigo pode ignorá-los, por isso a entrega pelo pipeline do aparelho continua sendo um ponto de validação.

Prévia das chamadas de desenho no Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1 -Frame view-general
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1 -Frame view-bridge
lua .tools/stadium-preview.lua 2
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1 -Frame view-stadium2
```

A vista geral da corrida pode ser acionada por X no console. As imagens locais são reconstruções das chamadas reais de desenho, não medição de FPS do Lupi.
