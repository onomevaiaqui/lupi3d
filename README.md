# Lupi Combat Rally 3D — carros sem sombra 5.1

Campeonato 3D para Lupi, com três pistas, quatro carros, combate, power-ups, menu Novo Jogo/Continue e save entre provas. A câmera permanece alta e inclinada, com orientação fixa, acompanhando a posição do jogador.

## Revisão 5.1: carroceria e menos sombra

As sombras projetadas sob os quatro carros foram removidas em ALTO e LEVE, incluindo a malha e a etapa de desenho usadas para elas. O Fusca passou de 76 para 82 triângulos: separação do capô/tampa traseira e vidros, teto com seis seções e rodas com perfil hexagonal e volume. Os adversários mantêm 32 triângulos, com teto afunilado, vidros inclinados e rodas mais expostas.

A paleta usa contraste mais suave entre as cores claras/escuras das faces (fator 0,78 em vez de 0,62), sem acrescentar cores ou cálculos de luz. Essas cores fixas ajudam a ler o volume; não são sombras projetadas e o escurecimento delas não muda a quantidade de triângulos.

Nos mesmos 576 pontos/ângulos, ALTO manteve o pico de 279 triângulos; LEVE passou de 207 para 221, pois as novas inclinações/rodas expõem mais faces. O teste com todos os efeitos ativos ficou em 305. A maior soma de áreas projetadas caiu ligeiramente de 67.687 para 66.820 pixels. Isso não garante manter FPS no console.

Para prévia ampliada das malhas reais: lua .tools/car-preview.lua; use o argumento rival para o adversário. Depois execute render-check.ps1 com -Frame view-car ou view-rival. A câmera da corrida foi mantida.

## Revisão gráfica

O modo **ALTO** é o padrão desta versão de teste. Acrescenta árvores com três camadas de copa, pedras facetadas, cabanas com telhado/porta/janelas, cercas, marcação central no asfalto, chama de nitro e explosões com volume 3D. As malhas estáticas são compartilhadas e os efeitos usam pools limitados.

**L alterna ALTO/LEVE durante a corrida, sem reiniciar.** LEVE remove os novos objetos decorativos, marcações e chamas, e usa as árvores simples anteriores. Explosões e rastros de tiros permanecem para comunicar o combate. O cabeçalho mostra o modo e a quantidade de triângulos enviados, junto do FPS informado pelo firmware.

Não há sombras projetadas dos carros. Toda a pista, carros, árvores, itens, construções e efeitos descritos usam XYZ/perspectiva/triângulos. A interface e o semáforo são 2D. O chão plano é preenchido por um retângulo até o limite da área de jogo, equivalente ao fundo da câmera que olha para o chão.

Nos testes de 576 vistas das três pistas, com os quatro carros próximos:

| Modo | Pico de triângulos por quadro |
| --- | ---: |
| LEVE | 221 |
| ALTO | 279 |
| ALTO com todas as minas, rastros, explosões e nitros ativos no teste de estresse | 305 |

Não houve descarte por estouro do pool, limitado a 512. O carro do jogador usa 82 triângulos; cada adversário, 32. Cada árvore detalhada tem 16; pedra 12; cabana 24; cerca 20; chama 3; explosão 8. O modo ALTO aumenta o custo e pode reduzir FPS: o objetivo é medir o limite no console, não prometer 24 FPS.

## Áudio: correção baseada nos jogos oficiais

O usuário confirmou silêncio e o aviso de som indisponível na versão anterior. A documentação pública antiga descreve `sfx.fx`, mas o [Caio Pernocas atual](https://github.com/lupi-org-br/caio-pernocas/blob/main/soundtrack.lua) usa **music.loop(caminho, fade)** com arquivos **Furnace .fur**. O [Balão Gatinho](https://github.com/lupi-org-br/balao-gatinho/blob/main/cols.lua) usa o backend legado `sfx.fx` com IDs de samples diferentes de zero.

O áudio introduzido na revisão 5.0 prefere `music.loop` quando disponível e inclui **18 composições/efeitos originais em music/*.fur**, aproximadamente 5 KB no total. Não copia músicas, samples ou instrumentos dos jogos de referência. Os arquivos usam o formato v173 com síntese NES, também identificado nos módulos do Caio, sem PCM/WAVs grandes na RAM Lua.

Inclui tema do menu, navegação, confirmação, semáforo, motor em quatro faixas de velocidade, freada/derrapagem, tiro, colocação de mina, dano, explosão, coleta, nitro e resultado. A freada toca ao frear em movimento; curvas fortes em alta velocidade também disparam o efeito. O nitro produz um som mais agudo enquanto está ativo. Sons de combate muito distantes do jogador são filtrados.

**Limitação do backend confirmado:** music.loop é um único fluxo de música. Os efeitos curtos interrompem o tema/motor por um instante e depois o restauram. As faixas de motor têm múltiplas vozes sintetizadas; não há quatro gravações de motores independentes com áudio espacial. Explosão e resultado têm prioridade sobre tiro/navegação. Mudanças de rotação são agrupadas para evitar recarregar arquivos a cada quadro.

Se só `sfx.fx` existir, o fallback usa os IDs 3 e 62 observados nos jogos oficiais, com pulsos de motor, melodia simples de menu e eventos. O volume legado é configurado por `sfx.volume`. No backend moderno, ajusta `music.volume` apenas se a função e CH_ALL estiverem disponíveis, seguindo a assinatura usada pelo Caio.

No menu:

- **SOM: FUR** indica que music.loop foi encontrado; **SFX**, o backend antigo.
- **X: TESTAR** dispara o som de confirmação.
- **SEM API** indica que nenhum dos dois backends foi exposto.
- **FUR ERRO / SFX ERRO** mostra também a mensagem retornada pela chamada. Falhas de carregamento têm espera de dois segundos antes de tentar novamente, para não sobrecarregar o jogo.

Os 18 módulos foram abertos e renderizados pelo executável oficial Furnace 0.6.8.3 e todos produziram PCM não silencioso. Isso valida os arquivos, mas **o carregamento pelo firmware, a entrega dos .fur pelo servidor de atualização, a saída de áudio e o volume do console ainda precisam de teste no aparelho**. Usamos a mesma pasta/caminho `music/nome` dos exemplos oficiais.

O codec público antigo ignora .fur. O repositório inclui os arquivos fonte como nos jogos oficiais; nosso pacote independente também os preserva como arquivos binários no manifesto, sem convertê-los para Lua ou inventar um tipo de recurso específico. Se o pipeline do console não os entregar, será necessário ajustar esse pipeline, não repetir chamadas ao sample zero.

## Controles

| SNES | Ação |
| --- | --- |
| Cruz no menu | Escolher opção/pista |
| B no menu | Confirmar |
| X no menu | Testar som |
| B na corrida | Acelerar |
| A na corrida | Frear, com prioridade sobre B |
| Cruz esquerda/direita | Esterçar |
| R | Uma carga da arma equipada por aperto |
| Y na corrida | Reiniciar pista e semáforo |
| Y na seleção/resultado | Menu |
| L na corrida | Alternar ALTO/LEVE |

Padrão `controller="snes"`: B=BTN_Z, A=BTN_G, R=BTN_E, Y=BTN_F, L=BTN_Q. No perfil direto do simulador `lupinho`, usa BTN_Z/BTN_X/BTN_G/BTN_Q/BTN_F respectivamente.

## Campeonato e combate

Três pistas selecionáveis: Vale Oval (~165 unidades), Cruzamento 8 (~227) e Serra Verde (~180). Cada prova tem três voltas, jogador e três adversários que também coletam/usam itens. Vermelho por dois segundos, amarelo por um e verde para liberar carros/cronômetro. Checkpoints em ordem distinguem os ramos do cruzamento e impedem voltas cruzando a chegada de ré.

Novo Jogo zera o progresso. Continue é liberado após pelo menos uma pista em primeiro lugar. Vença **duas pistas diferentes** para ser campeão; repetir a mesma vitória não aumenta o total. Ainda é possível disputar a terceira. A classificação considera o avanço no percurso e quem já terminou.

| Power-up | Cargas / efeito |
| --- | --- |
| Amarelo: tiro | 3 tiros frontais, alcance 15, dano 35 |
| Vermelho: mina | 2 minas, dano 50, arma em 0,5 s e dura 18 s |
| Azul: nitro | Automático por 5 s; aceleração e velocidade máxima +10% |

Uma arma por vez: tiro/mina substituem o tipo e recarregam as cargas. Nitro coexiste com a arma. Caixas voltam após nove segundos. Minas armadas podem atingir o próprio dono. Vida 100; destruído, o carro para por dois segundos, perde os itens e retorna com vida cheia no mesmo progresso. Limite de oito minas, quatro rastros e quatro explosões. Sem espaço para outra mina, a carga não é consumida.

Os carros ainda podem se atravessar; não há física de colisão entre eles. Árvores, pedras, casas e cercas são decorativas, sem colisão. A grama desacelera. As decisões de combate dos adversários são avaliadas quatro vezes por segundo.

## Save e compatibilidade

Ao terminar cada pista, salva a melhor colocação e a próxima seleção. Continue só libera após uma vitória. Y não apaga vitórias. Não salva no meio da corrida. O formato do save anterior é mantido.

Dois arquivos pequenos alternados, rally-save-0.dat e rally-save-1.dat, têm versão, geração e checksum; um arquivo inválido pode ser recuperado pelo anterior. Usa io.open na pasta do aplicativo quando é possível descobri-la por package.searchpath; sem package, usa a pasta relativa atual. config.save_dir permite outra pasta existente. O console já confirmou ausência da tabela package; não é exigida.

O resultado mostra **PROGRESSO SALVO** somente após gravar e reler com sucesso, ou **SAVE INDISPONIVEL**. Sem acesso a arquivos, mantém apenas o progresso da sessão. Persistência real continua dependendo do suporte do firmware. Novo Jogo substitui os saves.

## Build e testes

Tela 480x270, 32 cores, BGR555 preservado. Distância de desenho 42 unidades; geometria fora da visão descartada antes da projeção. Sem texturas, z-buffer ou luzes dinâmicas. A cena selecionada é construída sob demanda.

Pacote com 13 módulos Lua e 18 arquivos Furnace, aproximadamente 51 KB. O harness, que mantém várias corridas de teste simultaneamente, chegou a aproximadamente 1.248 KiB de heap Lua; não é a memória total usada no console. O custo do áudio no firmware não foi medido.

```sh
node .tools/build-audio.cjs
lua .tools/check-audio-api.lua
node .tools/check-audio.cjs
lua .tools/check-save.lua
lua .tools/check.lua
lua .tools/check-renderer.lua
node .tools/build.cjs
node .tools/check-discovery.cjs
lua .tools/check-release.lua
lua .tools/check-firmware.lua
```

Com `FURNACE_EXE` apontando para o executável oficial Furnace, check-audio.cjs também decodifica/renderiza os 18 módulos e verifica que o PCM não é silencioso. Sem o executável, verifica cabeçalhos compactados. O motor e o executável Furnace não são redistribuídos.

O build fica em .build/race-3d-release/, com manifesto e pasta music. Cabeçalho da versão: **LUPI COMBAT RALLY 5.1**. Testes preservam menu/Continue, três corridas completas, itens, checkpoints, semáforo, save real com recuperação de corrupção, renderização válida, comparação ALTO/LEVE, todos os efeitos ativos e inicialização sem package/io/os/debug/collectgarbage/sfx/music.

Prévia das chamadas de desenho no Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1 -Frame view-light
lua .tools/overview.lua 2
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1 -Frame view-track2
```
