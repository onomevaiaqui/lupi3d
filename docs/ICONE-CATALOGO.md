# Ícone animado para o catálogo do Lupi

O perfil atual do Combat Rally é **64 × 32 pixels**, restaurado na versão **13.5** a partir do ícone já validado na 12.8. Use esse tamanho para novos jogos.

## Limite confirmado pelo pipeline (19/11/2026)

O log real de sincronização rejeitou o arquivo de 128 × 64: `GIF canvas 128x64 exceeds 64x64`. Para animações em geral, o pipeline limita o canvas a 64 × 64; para o **ícone do catálogo**, a [documentação oficial](https://lupi.api.br/docs/assets.html) exige o tamanho exato de **64 × 32** e até 16 cores, incluindo transparência.

O usuário havia observado a exibição de 128 × 64 em um teste anterior, mas isso não garantiu sua aceitação na conversão atual. **Não reutilize o perfil experimental de 128 × 64.** O build e o teste de descoberta agora executam a validação do ícone antes de preparar o pacote.

## Perfil validado para reutilizar

| Propriedade | Valor usado |
| --- | --- |
| Arquivo | `icon.gif`, em minúsculas, na raiz do repositório |
| Formato | GIF89a animado |
| Resolução | 64 × 32 pixels, proporção 2:1 |
| Cores | Paleta indexada de 16 entradas, **idêntica em todos os quadros** |
| Transparência | Desativada |
| Quadros | 12 |
| Duração por quadro | 120 ms, aproximadamente 8,33 quadros/s |
| Duração do ciclo | 1,44 segundo |
| Repetição | Infinita, extensão NETSCAPE2.0 com contador 0 |
| Descarte de quadro | Método 1: manter o quadro anterior (`do not dispose`) |
| Compressão | LZW com tamanho inicial de código de 8 bits |
| Área de cada quadro | Imagem completa de 64 × 32, posição x=0, y=0 |
| Entrelaçamento | Desativado |
| Tamanho do arquivo validado | 6.354 bytes, aproximadamente 6,2 KiB |

O primeiro quadro usa a paleta global de 16 entradas. Os seguintes repetem a mesma tabela como paleta local, inclusive com **as mesmas cores nos mesmos índices**. Não basta limitar cada quadro separadamente a 16 cores: a tabela deve permanecer igual durante toda a animação.

No arquivo validado, o cabeçalho da tela lógica usa o byte de controle `0x83`, fundo 0 e proporção de pixel 0. O primeiro descritor de imagem tem controle `0x00`; os seguintes usam `0x83`. A extensão de controle de cada quadro tem os dados `04 0C 00 00`: método de descarte 1, sem transparência, atraso de 12 centésimos de segundo. Esses detalhes são conferidos pelo validador do projeto.

## Organização do repositório

```text
meu-jogo/
├── icon.gif
├── lupi.yaml
├── game.lua
└── ...
```

Exemplo de `lupi.yaml`:

```yaml
name: Meu Jogo
public: true
version: 1.0
```

O Rally não usa um campo `icon:` no YAML nem uma chamada Lua para mostrar essa miniatura. O arquivo fica na raiz da branch padrão pública do jogo. O ícone do catálogo é diferente da arte de Social Preview do GitHub e do menu inicial desenhado pelo próprio jogo.

## Como preparar a animação

1. Capture quadros do jogo em resolução maior que a do ícone. Gere a versão de 64 × 32 a partir dessas capturas. Não amplie o canvas acima desse tamanho para tentar ganhar nitidez: priorize enquadramento próximo e formas legíveis.
2. Recorte a cena na proporção 2:1 e preencha toda a imagem. Evite faixas pretas, HUD pequeno e texto difícil de ler. Aproxime os personagens ou veículos para que sejam reconhecíveis no catálogo.
3. Escolha **uma única paleta** de até 16 cores para a animação inteira. Ela pode vir da arte do seu jogo; não há evidência de que seja obrigatório usar as cores do Trumpsrun. No teste confirmado do Rally, usamos as mesmas cores desse exemplo funcional.
4. Converta todos os quadros usando essa paleta fixa, com os mesmos índices. Desative a criação de paletas independentes por quadro. A exportação pode reorganizar índices: confira o GIF final, não apenas as imagens de entrada.
5. Exporte 12 quadros completos, opacos, em 64 × 32, com atraso de 120 ms e repetição infinita. Preserve LZW com código inicial de 8 bits; alguns exportadores escolhem automaticamente 4 bits para imagens com 16 cores.
6. Decodifique o GIF exportado para conferir cores, movimento e preenchimento. Um GIF abrir no computador não garante compatibilidade com o console.
7. Salve como `icon.gif` na raiz, publique na branch padrão e atualize a versão em `lupi.yaml`, mantendo coerentes os números de versão usados pelo projeto. Confirme a exibição no catálogo do console.

Evite usar uma exportação automática sem conferir as tabelas: arquivos anteriores eram GIFs válidos no computador, mas não apareciam no Lupi.

## Verificação neste projeto

Na raiz do repositório:

```sh
node .tools/check-icon.cjs
```

O script valida o perfil acima: resolução, quadros completos, paleta fixa, temporização, repetição, ausência de transparência e LZW de 8 bits. Pode ser copiado para outro jogo se mantiver a estrutura `.tools/check-icon.cjs` e `icon.gif` na raiz. Ele não valida entrega pelo catálogo nem substitui o teste no hardware.

O limite de 32 KiB do script é um **orçamento adotado pelo projeto**, não um limite documentado do Lupi.

## O que aprendemos nos testes

- O GIF original do Trumpsrun apareceu quando colocado no repositório do Rally. Isso confirmou que o catálogo conseguia entregar um ícone para a entrada do jogo.
- As tentativas com mudanças de tamanho, compressão e retângulos dos quadros não resolveram sozinhas a ausência do ícone.
- O arquivo passou a aparecer na versão 12.7 depois que todos os quadros passaram a repetir a mesma paleta. O anterior tinha 16 paletas diferentes, somando 59 cores na animação. Esse resultado aponta para a paleta fixa como a condição decisiva neste teste, sem provar a implementação interna do firmware.
- A versão 12.8 confirmou a imagem preenchendo a área, sem faixas, em 64 × 32.
- Na versão 12.9, o usuário observou a exibição de 128 × 64; depois, o pipeline de sincronização rejeitou esse canvas. A 13.5 retorna ao perfil documentado de 64 × 32.

A documentação estabelece 64 × 32 e até 16 cores para o ícone, e até 64 × 64 para GIFs em geral. O limite de bytes e o comportamento de atualização em todos os firmwares não foram determinados. Para novos jogos, comece pelo perfil validado e altere uma variável por vez.

## Se o ícone não aparecer

Confira o nome e o caminho, o acesso público ao arquivo e a versão que está rodando no console. Depois valide as paletas de todos os quadros, a compressão e a transparência. Registre se a entrada ficou vazia ou manteve o ícone anterior: isso ajuda a distinguir falha de exibição de uma possível atualização pendente. Não há um procedimento público de limpeza de cache confirmado por estes testes.
