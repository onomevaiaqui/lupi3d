# Teste local: bosque em blocos

Experimento da versão 13.8, aprovado para publicação e teste no console.

- Somente Viaduto Sul (pista 8, Puerto Montt) recebe o experimento.
- Copas em degraus, troncos claros, cabanas de madeira, pedras em blocos e terreno mais claro.
- Modelos XYZ reais, projeção e recorte pelo renderizador existente. Sem sprites de cenário ou imagem de fundo.
- Carros, câmera, percurso, colisões, dificuldade e paleta de 36 cores preservados.
- Mantém as posições e a quantidade de objetos de decoração; compartilha as malhas entre instâncias.
- Cada árvore tem 30 triângulos, cada pedra 20 e cada cabana 26. Não há cubos individuais por voxel, sombras dinâmicas ou texturas novas.
- O novo cenário aparece nos detalhes altos; as árvores em blocos também aparecem no modo leve.

Prévia reproduzível: `lua .tools/preview-block-course.lua`, seguido de `.tools/render-check.ps1 block-course-N` para N de 1 a 5. Captura os comandos do jogo em 480x270; a rasterização e a fonte do visualizador local podem diferir do console.

Validação local: 90 vistas com seis carros, nos dois níveis de detalhe, sem estouro do pool; cinco capturas da pista com 429 a 495 triângulos enviados. Isso não mede FPS real no Lupi.

Para retirar o experimento, remover a chamada `blockCourse(T)` em `scenery.lua`. As demais otimizações locais são independentes deste teste.

A versão também inclui as otimizações locais já preparadas: reaproveitamento das tabelas de entrada, consultas idênticas de localização, trigonometria de colisões e temporizadores inativos. A limpeza das malhas elimina somente triângulos de área zero. O efeito de freada passa a disparar na entrada da manobra, evitando reinícios repetidos durante uma curva contínua. Nenhuma dessas alterações comprova um ganho de FPS ou resolve por si só o áudio no hardware.
