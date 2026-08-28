# Cat

Widget Cat sensível à mesa digitalizadora para o Noctalia. Ele dorme quando a MTM-1106/T501 está desconectada e caminha quando a mesa está conectada.

## Plugin

| Campo | Valor |
| --- | --- |
| ID | `dotnetrob/cat` |
| Entradas | widget de barra `cat`; panel `panel` |
| Panel | attached, 360×380 pixels lógicos, aberto próximo ao clique |

## Uso

Adicione o widget **Cat** em **Settings → Bar → Add Widget**. Clique nele para abrir o panel attached, que usa a surface nativa do Noctalia. O painel amplia o mesmo gato do widget usando a fonte animada `catwalk2.otf`: ele caminha quando a mesa está conectada e dorme quando ela está desconectada.

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

O botão **New Xournal** chama `livara-xournal-new-note`. Ele abre a nota do dia em `~/Vault/02 - Xournal++` ou reabre o arquivo existente. A configuração nativa do Xournal++ fornece o template e o ajuste de zoom. O botão fica visualmente secundário e informa que a mesa está inativa quando o dispositivo não está conectado.

O botão **New Daily** chama `livara-obsidian-daily-note`, que abre a ação oficial `obsidian://daily?vault=Vault`. A pasta, o formato e o template continuam sob responsabilidade do Daily Notes core do Obsidian.

## Assets

O painel e a barra usam a mesma fonte `catwalk2.otf`, mantendo glyph, cor adaptativa e estado walking/sleep sincronizados por `noctalia.state`. Não há uma segunda animação ou asset visual para o painel.
