# Lupi Combat Rally 3D (4.0)

Protótipo de campeonato de corrida e combate, com menu inicial, três pistas selecionáveis, quatro carros, power-ups, sons e save entre provas. Cenário, carros e itens usam malhas XYZ e triângulos nativos do Lupi. A interface e o semáforo são 2D.

## Controles

| Controle SNES | Ação |
| --- | --- |
| Cruz no menu | Escolher opção / pista |
| B no menu | Confirmar |
| B na corrida | Acelerar |
| A na corrida | Frear; tem prioridade sobre B |
| Cruz esquerda/direita | Esterçar |
| R | Acionar uma carga do item armado, uma vez por aperto |
| Y na corrida | Reiniciar a pista e o semáforo |
| Y na seleção ou resultado | Voltar ao menu |

O perfil padrão mantém os códigos já utilizados: B=`BTN_Z`, A=`BTN_G`, R=`BTN_E`, Y=`BTN_F`. No modo direto `controller="lupinho"`, usa BTN_Z/BTN_X/BTN_G/BTN_Q respectivamente. Mantenha o perfil SNES no console.

## Menu, pistas e campeonato

- **Novo Jogo** zera o progresso salvo e abre a seleção de pistas.
- **Continue** fica desabilitado até vencer pelo menos uma pista em primeiro lugar. Depois carrega o progresso e abre a seleção.
- As três pistas podem ser escolhidas livremente: **Vale Oval** (~165 unidades), **Cruzamento 8** (~227) e **Serra Verde** (~180).
- Cada prova tem três voltas, o jogador e três adversários vermelhos/azuis/verdes. O cruzamento da pista 8 é plano.
- Para conquistar o campeonato, vença **duas pistas diferentes em primeiro lugar**. Repetir uma vitória na mesma pista não aumenta esse total. Ainda é possível vencer a terceira.
- O semáforo mantém todos parados por três segundos: vermelho por dois, amarelo por um e verde para largar. O cronômetro inicia no verde.
- A primeira passagem pela chegada inicia as voltas. Quatro setores em ordem impedem que cruzar de ré some voltas; a pista 8 distingue os dois ramos pelo progresso anterior.
- A classificação considera o avanço no percurso e os adversários que já terminaram. A prova encerra quando o jogador completa três voltas.

Os adversários seguem a linha central e também coletam e usam itens. Neste protótipo os carros podem se atravessar; as árvores são decorativas, sem colisão. A grama desacelera o jogador, e frear nas curvas ajuda a manter o traçado.

## Power-ups e combate

| Cor | Item | Efeito |
| --- | --- | --- |
| Amarelo | Tiro | 3 cargas; R dispara um tiro frontal |
| Vermelho | Mina | 2 cargas; R deixa uma mina atrás do carro |
| Azul | Nitro | Ativa automaticamente por 5 segundos: aceleração e velocidade máxima +10% |

Tiro e mina ocupam o mesmo espaço de arma: coletar outra arma substitui o tipo e as cargas. Nitro pode coexistir com a arma. As caixas retornam após nove segundos e podem ser coletadas pelos adversários.

O tiro calcula o primeiro carro alinhado à frente, com alcance de 15 unidades, e causa 35 de dano. A mina arma em 0,5 segundo, dura até 18 segundos e causa 50 de dano; depois de armada pode atingir inclusive seu dono. Vida inicial de 100. Ao chegar a zero, o carro fica parado/invisível por dois segundos, perde arma/nitro e volta com vida cheia no mesmo ponto de progresso.

Há limite de oito minas e quatro rastros de tiros simultâneos, com estruturas reutilizadas. Sem espaço para outra mina, a carga não é consumida. As decisões de combate de cada adversário são avaliadas quatro vezes por segundo.

## Save

O jogo grava automaticamente ao terminar **cada pista**, inclusive quando perde, preservando a melhor colocação de cada uma. Continue só é liberado depois de um primeiro lugar. Reiniciar a pista por Y não apaga as vitórias anteriores. Não há save no meio da corrida.

São usados `rally-save-0.dat` e `rally-save-1.dat`, arquivos pequenos com versão, geração, melhores colocações, próxima seleção e checksum. As gravações alternam entre os dois: se o arquivo mais recente estiver inválido, o anterior válido pode ser carregado. O save é dado de texto validado, nunca código executado.

A pasta padrão é a pasta do aplicativo, obtida por `package.searchpath`; `config.save_dir` permite definir outra pasta existente. O módulo usa `io.open` da biblioteca Lua, disponível no simulador. **A documentação pública consultada não apresenta uma API de save específica: gravação na pasta do app ainda precisa ser validada no firmware do console.**

O resultado mostra **PROGRESSO SALVO** após gravar e reler com sucesso, ou **SAVE INDISPONIVEL** quando não consegue persistir. Nesse segundo caso, o jogo continua e mantém o progresso apenas durante a sessão. Remover os dados do aplicativo remove os saves. Novo Jogo substitui o progresso do campeonato.

## Som

Menu, semáforo, tiro, mina, coleta, dano, resultado e pulsos do motor chamam a API documentada `sfx.fx(0, nota, 0.5)`. Usa o sample 0 do banco do firmware, com notas diferentes; não carrega WAVs grandes na memória Lua. O motor é um efeito tonal simples, não uma gravação realista.

A presença da API e a ausência de erro são indicadas no menu por **SOM: API OK**. Isso não confirma que o banco de samples do aparelho contém um som audível no índice zero: áudio e volume precisam de teste no console. Se a API não estiver presente ou falhar, mostra **SOM: NAO DISPONIVEL** e continua sem travar. O simulador público consultado não expõe essa API de áudio; os testes locais validam as chamadas com um stub.

Referência: https://lupi.api.br/docs/system.html

## Orçamento e desempenho

Renderização por software em Lua: projeção em perspectiva, descarte de faces traseiras e de objetos fora da visão, recorte próximo/na tela, ordenação por profundidade média, envio de triângulos inteiros válidos a `ui.trisfill`. Sem z-buffer, texturas ou luzes dinâmicas.

- Tela: 480 x 270; paleta: 32 cores, mantendo BGR555 que funcionou no aparelho.
- Carro do jogador: 76 triângulos, 88 vértices XYZ compartilhados.
- Adversários: 32 triângulos cada, com geometria compartilhada e cores distintas.
- Só a pista selecionada é construída; árvores e trechos fora da visão são descartados antes da projeção.
- Câmera preservada em 6,4 unidades atrás e altura 3,3. Distância de desenho de 30 unidades; zebras até 18 unidades.
- Em 576 vistas locais das três pistas, com quatro carros próximos: pico de **185 triângulos enviados por quadro**, sem estouro do pool de 384. Um teste com todas as minas e rastros ativos também passou.
- Pacote de 12 módulos Lua, aproximadamente 37 KB. O harness completo, mantendo várias corridas de teste ao mesmo tempo, ficou em aproximadamente 803 KiB de heap Lua; isso não mede a memória total do console.

**Ainda não há FPS desta versão no Lupi.** Quatro carros, combate e som aumentam o trabalho. Tempos de execução no computador não garantem 24 FPS no aparelho.

## Executar e testar

`lupi.yaml` e `game.lua` ficam na raiz para descoberta. O menu deve mostrar **LUPI COMBAT RALLY 4.0**.

```sh
lua .tools/check-save.lua
lua .tools/check.lua
lua .tools/check-renderer.lua
node .tools/build.cjs
node .tools/check-discovery.cjs
lua .tools/check-release.lua
```

O pacote vai para `.build/race-3d-release/`, com módulos e manifesto; não inclui motor ou banco de samples. Não distribui os arquivos de save de teste.

Os testes cobrem as três corridas completas usando controles reais, diferentes FPS, classificação, checkpoints, semáforo, todos os itens e cargas, vida/retorno, chamadas de áudio, falha de áudio, menus e Continue, campeão por vitórias distintas, save real em disco, recarga, arquivo corrompido, limpeza por Novo Jogo e falha em pasta sem escrita.

Prévia das chamadas de desenho no Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1 -Frame view-menu
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1 -Frame view-select
lua .tools/overview.lua 1
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/render-check.ps1 -Frame view-track1
```

Troque 1 por 2 ou 3 para as outras pistas. As imagens superiores projetam as malhas XYZ reais para inspeção.
