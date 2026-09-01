# FreeSM Launcher Instances

Este provider adiciona as instâncias locais do FreeSM Launcher ao launcher do Noctalia. O FreeSM é um fork compatível com o formato de instâncias do Prism Launcher.

| Campo | Valor |
| --- | --- |
| ID | `radimous/prismlauncher-instances` |
| Entrada | Launcher provider: `prismlauncher-instances` |
| Prefixo | `/pl` |
| Dados | Launcher Root configurável; default `~/.var/app/org.freesmlauncher.FreesmLauncher/data/FreesmLauncher` |
| Execução | `flatpak run org.freesmlauncher.FreesmLauncher --launch <instance>` via argv direto |

## Requisitos

O Flatpak `org.freesmlauncher.FreesmLauncher` precisa estar instalado. O provider não instala nem modifica instâncias; ele lê `instance.cfg`, metadados e ícones do Launcher Root configurado. Para a raiz padrão ele lê `prismlauncher.cfg`; para raízes customizadas, procura de forma determinística no nível superior por um arquivo `.cfg` ou `.ini` que contenha `InstanceDir`, sem usar glob literal em `readFile`.

## Uso

Abra o launcher do Noctalia, digite `/pl` e continue digitando para filtrar pelo nome da instância. Ao ativar um resultado, o provider executa o FreeSM Flatpak com `--launch` e o identificador da instância. O comando é enviado ao runtime como vetor de argumentos, sem `sh -c`, sem `&>/dev/null` e com erro de saída encaminhado ao log/notificação do Noctalia; isso evita o caminho shell-string que mascarava falhas de IPC como o aviso `QLocalSocket`.

Se o FreeSM estiver configurado para um Launcher Root diferente, ajuste `prism_path` em Settings → Plugins → FreeSM Launcher Instances. A alteração deve apontar para o diretório que contém `instances/` e os arquivos de configuração do launcher.

## Segurança e escopo

A configuração usa o comando Flatpak como default para não depender de um binário `prismlauncher` nativo no `PATH`. O plugin não cria conta, altera configurações, baixa conteúdo ou modifica os arquivos do FreeSM; apenas enumera instâncias e solicita o lançamento da selecionada.
