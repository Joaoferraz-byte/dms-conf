# Cat

Widget Cat sensível à mesa digitalizadora para o Noctalia. Ele dorme quando a MTM-1106/T501 está desconectada e caminha quando a mesa está conectada.

## Plugin

| Campo | Valor |
| --- | --- |
| ID | `dotnetrob/cat` |
| Entradas | widget de barra `cat`; panel `panel` |
| Panel | attached, 360×380 pixels lógicos, aberto próximo ao clique |

## Uso

Adicione o widget **Cat** em **Settings → Bar → Add Widget**. Clique nele para abrir o panel attached, que usa a surface nativa do Noctalia. A animação `kurukuru.gif` aparece acima do botão **New Xournal++ Note**; seis frames PNG são usados porque `ui.image` apresenta uma textura por vez.

O panel também pode ser aberto por IPC:

```sh
noctalia msg panel-toggle dotnetrob/cat:panel
```

Clique fora do panel para fechá-lo.

## Configurações

| Configuração | Tipo | Padrão | Descrição |
| --- | --- | --- | --- |
| `cat_size` | `int` | `24` | Tamanho do sprite na barra, entre 12 e 48 pixels. |
| `cat_color_mode` | `select` | `theme` | Usa a cor `secondary` do tema ou uma cor customizada. |
| `cat_color` | `color` | `#E8A24C` | Cor usada quando `cat_color_mode = "custom"`. |

## Mesa e Xournal++

O widget consulta `livara-tablet-status` a cada 1,5 segundo. O helper é somente leitura e não inicia nem encerra o driver.

O botão **New Xournal++ Note** chama `livara-xournal-new-note`. Ele abre a nota do dia em `~/Vault/02 - Xournal++` ou reabre o arquivo existente. A configuração nativa do Xournal++ fornece o template e o ajuste de zoom.

## Assets

O `kurukuru.gif` original permanece preservado. A origem e a extração determinística dos frames estão em [`ASSET-SOURCE.md`](ASSET-SOURCE.md). O sprite da barra usa `catwalk2.otf` para continuar leve e adaptado ao tema.

## Migração de estado

`repair-noctalia-stale-bars` é um reparador one-shot para estados antigos que apontam panels para uma barra removida. Ele não é necessário em logins normais; use-o somente quando houver `[bar.main]` ou `panel_anchor_bar = "main"` no estado persistido.
