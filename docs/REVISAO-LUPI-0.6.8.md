# Revisão do Lupi e dificuldade — 13.2

Consulta à documentação pública em **10/11/2026**. O site identifica a API como firmware **0.6.8**, ainda em construção. Isso não confirma a versão instalada no aparelho do jogador.

## APIs e comportamento conferidos

| Área | Contrato público e situação do Rally |
| --- | --- |
| Entrada | `game.lua`, `update(frame)` e módulos por `require`. O projeto mantém essa organização. |
| Renderização | Tela 480 × 270; `ui.trisfill` recebe três coordenadas 2D e um índice de cor. O Rally continua projetando suas malhas XYZ em Lua e enviando triângulos recortados. |
| Cores | BGR555 e até 256 índices. O jogo continua usando somente 32 e registrando a paleta a cada desenho. Não houve mudança de cores ou malhas. |
| Controles | `ui.btn(botao, jogador)` retorna `false` ou pressão positiva. A leitura já aceita ambos; as constantes do firmware são usadas, sem números fixos no jogo. |
| Estatísticas | `ui.stat(7)` informa FPS; 0 informa memória Lua em bytes e 1 informa CPU. A temporização atual continua usando o FPS reportado, com fallback. |
| Bibliotecas | `table`, `string`, `math` e `utf8`; sem `io` ou `os`. Os acessos opcionais de save/diagnóstico continuam protegidos. Não foi inventada uma API de persistência que a documentação não oferece. |
| Música | `.fur` é convertido no serviço para `.las`; chamadas usam caminho sem extensão. `music.loop` é preferido para temas/motores, `music.play` para eventos quando disponível. |
| Legado de áudio | `sfx.fx` não consta na página nova. Sua compatibilidade foi mantida para aparelhos antigos, mas não toma mais prioridade automática quando `music.loop` existe. X ainda permite o diagnóstico alternativo antigo. |
| Ícone | A página nova pede exatamente 64 × 32, até 16 cores. O ícone de 128 × 64 já foi confirmado neste console e foi preservado. Essa divergência está registrada no guia do ícone. |

O pacote local de teste copia os `.fur` originais; a conversão `.las` pertence ao serviço do Lupi. Não é necessário renomear arquivos manualmente nem mudar os caminhos de reprodução.

## Dificuldade

`config.rival_difficulty=1.15` multiplica o ritmo-alvo e a aceleração dos rivais, relativamente à versão 13.1. A progressão pelos países/pistas e a variação de forma entre pilotos continuam. Esse é um aumento mensurável de parâmetros da IA, não uma previsão de redução de 15% na chance de vitória. Os atributos, a velocidade e os upgrades do jogador permanecem iguais.

Não há atualização de potência baseada na distância ao jogador durante a prova. Os alvos são calculados na criação da corrida. A IA é paramétrica: seu ritmo é um parâmetro de equilíbrio separado do limitador de velocidade aplicado ao carro controlado manualmente.

## Upgrades aleatórios dos inimigos

Para cada nível comprado, um ou dois rivais distintos recebem a mesma categoria de peça. A sequência pseudoaleatória continua derivada do nome do jogador, tipo e nível da peça, para poder reconstruir os resultados usando o save existente. Não há sorteio novo a cada reinício. Campanhas com o mesmo nome e os mesmos níveis têm a mesma distribuição.

A correção desta versão é selecionar **somente rivais cuja peça ainda esteja abaixo do nível 3**, evitando desperdiçar uma melhoria em uma peça já no máximo. O segundo escolhido é retirado do mesmo conjunto de elegíveis depois de excluir o primeiro. Motor, pneus e blindagem continuam afetando os atributos reais usados na corrida. O formato do save não mudou.

## Testes e limites

- `node .tools/check-discovery.cjs`: pacote e manifesto.
- `node .tools/check-icon.cjs`: preservação do ícone validado.
- `lua .tools/check-difficulty.lua`: aumento de exatamente 15% no ritmo-alvo dos cinco rivais, nas 15 pistas, com grids e upgrades iguais; atributos do jogador preservados; distribuição de peças, malhas e saves.
- `lua .tools/check-firmware068.lua`: execução sem IO/OS/package/GC, constantes documentadas, paleta, triângulos recortados, 15 corridas com seis carros, menus e áudio moderno simulado.
- `lua .tools/check-firmware.lua` e `lua .tools/check-release.lua`: carregador restrito e pacote publicado.
- `lua .tools/check-audio-api.lua`: chamadas de música, eventos únicos, prioridade/restauração, falhas e ausência da API.

O teste antigo de áudio ainda tinha expectativas de flags de diagnóstico de volume que já não existiam na implementação. Ele foi atualizado para verificar os contratos atuais de reprodução, incluindo preferência pelo backend documentado e eventos únicos.

Esses testes não comprovam áudio audível, FPS, qualidade de condução ou persistência entre reinicializações no console. Sem uma API de armazenamento disponível, o fallback de progresso é a sessão atual. A calibragem do desafio deve ser conferida no hardware, principalmente no Brasil com carros preparados.

## Fontes oficiais consultadas

- [Introdução, hardware e BGR555](https://lupi.api.br/docs/).
- [Ciclo do jogo, bibliotecas, controles e estatísticas](https://lupi.api.br/docs/system.html).
- [Primitivas gráficas](https://lupi.api.br/docs/graphics.html).
- [Áudio, canais e volume](https://lupi.api.br/docs/audio.html).
- [Assets, ícones, YAML e chips Furnace aceitos](https://lupi.api.br/docs/assets.html).
- [Utilitários nativos](https://lupi.api.br/docs/util.html). Nenhuma rotina geométrica foi substituída sem medição ou evidência de ganho.
