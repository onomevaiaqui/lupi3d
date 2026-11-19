# Otimizações 13.9

Mantém o jogo integralmente em 3D, os seis modelos completos, a paleta, a câmera, as colisões, as quinze pistas e o experimento de bosque na pista 8.

## Alterações

- O renderizador rejeita volumes inteiramente fora da tela antes de projetar seus vértices. Objetos estáticos usam limites preparados no espaço da câmera; objetos móveis usam esferas que contêm a malha inteira. Há margem conservadora nas bordas.
- Objetos inteiramente à frente do plano próximo usam uma projeção que evita gravar coordenadas temporárias não consumidas pelo desenho. Objetos que cruzam esse plano continuam no recorte completo.
- Os limites dos carros e efeitos são preparados na abertura da corrida; as estruturas das chamas também. As tabelas de entrada da corrida e do áudio são reutilizadas. Minas, tiros e explosões já tinham pools e foram mantidos.
- A localização na pista reutiliza seu contexto de consulta, eliminando a função temporária por chamada. Cada pista tem seu próprio contexto; as consultas são síncronas.
- As listas de asfalto no solo e elevado são separadas ao carregar a pista. O desenho não percorre a camada errada para descartá-la novamente.
- O preenchimento inicial azul foi eliminado somente durante a corrida: terreno e barras do HUD já cobrem toda a tela. A ordenação e as sobreposições dos objetos 3D foram preservadas. Não foi introduzido descarte por oclusão aproximado, que poderia esconder carros ou partes dos viadutos.
- Decisões de ataque mantêm sua fase de 0,25 segundo após um frame demorado. Evita sincronizar os cinco oponentes, mantendo quatro avaliações por segundo por piloto. Movimento, altura e colisões continuam em cada passo da física. A nova distribuição pode mudar a sequência dos ataques aleatórios.

## Diagnóstico no Lupi

No menu inicial, segure **X + R** para alternar o diagnóstico. Solte os botões antes de começar a corrida. O mesmo atalho desliga o diagnóstico no menu. Os controles da corrida não mudam.

A sobreposição mostra CPU e memória Lua, consultadas a cada 30 desenhos, além de objetos submetidos/descartados, vértices projetados, triângulos desenhados, avaliações de IA, passos de física, reconstruções de cache e descartes antecipados. O FPS continua no HUD habitual. `CACHE` tende a zero durante uma corrida com câmera fixa. Esses contadores representam trabalho por quadro, não milissegundos por etapa.

A API documentada oferece `ui.stat(0)` para memória Lua em bytes, `ui.stat(1)` para CPU e `ui.stat(7)` para FPS. Não oferece relógio de alta resolução para cronometrar etapas; `os` não existe no console. Não se interpreta uma leitura de CPU como duração de uma função. Referência: https://lupi.api.br/docs/system.html.

## Validação e limites

- 127 vistas de corrida e menus: comandos geométricos idênticos, nenhum pixel alterado no comparador local.
- 8.000 vistas aleatórias com descarte ligado/desligado, incluindo modelos móveis, caches e recorte próximo: triângulos idênticos. Em 7.187 casos, o objeto inteiro pôde ser rejeitado antes da projeção.
- 10.000 consultas de pista sem crescimento de alocações no laço testado.
- IA validada a 8, 15, 20, 24, 30 e 60 FPS: mantém a frequência e evita a sincronização dos cinco pilotos. Movimento e colisões não são escalonados entre frames.
- Física e combate iguais à 13.8 em quinze corridas com sementes fixas quando a nova distribuição das decisões é desativada para isolar as otimizações.
- Benchmark em Lua no computador, mediana de cinco execuções: física 0,289 s → 0,269 s, cerca de 7% menos tempo; desenho da largada da pista 8, 1.131 s → 1.118 s para 1.800 quadros, cerca de 1%. Vértices por quadro nessa vista: 871 → 839; triângulos: 506 → 506.

Os benchmarks substituem as funções nativas de desenho por funções vazias: **não medem o rasterizador, o FPS nem o tempo real no Lupi**. A remoção do preenchimento redundante deve ser avaliada no hardware. Não há promessa de 24 ou 60 FPS.

Scripts: `.tools/check-early-culling.lua`, `.tools/check-runtime-work.lua`, `.tools/check-render-physics.lua`, `.tools/capture-render.lua`, `.tools/compare-render.cjs` e `.tools/benchmark-runtime.lua`. O benchmark aceita um diretório de módulos como argumento para comparar com uma cópia da versão anterior.
