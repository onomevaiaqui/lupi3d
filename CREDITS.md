# Assets gratuitos da itch.io

Autor: **Kay Lousberg / KayKit**, https://kaylousberg.com/.

Licença dos dois packs: **Creative Commons Zero (CC0 1.0)**. Os arquivos de licença distribuídos pelo autor estão em `.assets-source/LICENSE-Adventurers.txt` e `.assets-source/LICENSE-Forest.txt`. Código do teste: MIT, em `LICENSE`. Os modelos originais e derivados mantêm CC0.

## Personagem

- Página: https://kaylousberg.itch.io/kaykit-adventurers
- Download gratuito **Free 2.0**, upload itch.io `15363167`, baixado em 31/10/2026.
- Arquivo selecionado: `Characters/gltf/Knight.glb`, preservado em `.assets-source/Knight.glb`.
- SHA-256 do ZIP baixado: `ABE48F4763FBA0896BAB486EE9E6D08CA6B5B3884B9601F235C8847AE94DC479`.
- Derivados: malhas simplificadas quality e fast em `models.lua`, recolorida, sem texturas/esqueleto, braços abaixados, sem capa e com a cabeça interna ao capacete preservada, membros identificados para caminhada procedural.

## Cenário

- Página: https://kaylousberg.itch.io/kaykit-forest
- Download gratuito **Free / Forest Nature Pack 1.0**, upload itch.io `13520330`, baixado em 31/10/2026.
- Arquivos selecionados: `Assets/obj/Tree_1_A_Color1.obj` e `Assets/obj/Rock_1_A_Color1.obj`, preservados em `.assets-source/`.
- SHA-256 do ZIP baixado: `2EE83E63BB7695F2D884EC27DDF6FCE020789A452E7D5C5B0BBDFC4F6EA1FC8C`.
- Derivados: malhas simplificadas (incluindo árvore com 32 triângulos e pedra leve com 16) e cores chapadas em `models.lua`. Materiais e atlas originais não são usados.

Chão e código de projeção/controle foram criados para este teste. Não fazem parte dos packs.

## Ferramenta de conversão

meshoptimizer 1.3.0, Arseny Kapoulkine, licença MIT. Apenas no computador, em `.tools/vendor/meshopt_simplifier.mjs`. Licença incluída em `.tools/vendor/LICENSE-meshoptimizer.txt`. Origem: https://www.npmjs.com/package/meshoptimizer/v/1.3.0 e https://github.com/zeux/meshoptimizer. A biblioteca não faz parte da execução no Lupi.
