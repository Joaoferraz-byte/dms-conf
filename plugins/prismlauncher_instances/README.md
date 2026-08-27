# FreeSM Launcher Instances

Este provider adiciona as instâncias locais do FreeSM Launcher ao launcher do Noctalia. O FreeSM é um fork compatível com o formato de instâncias do Prism Launcher.

| Campo | Valor |
| --- | --- |
| ID | `radimous/prismlauncher-instances` |
| Entrada | Launcher provider: `prismlauncher-instances` |
| Prefixo | `/pl` |
| Dados | `~/.var/app/org.freesmlauncher.FreesmLauncher/data/PrismLauncher` |
| Execução | `flatpak run org.freesmlauncher.FreesmLauncher --launch <instance>` |

## Requisitos

O Flatpak `org.freesmlauncher.FreesmLauncher` precisa estar instalado. O provider não instala nem modifica instâncias; ele lê `instance.cfg`, metadados e ícones do diretório configurado.

## Uso

Abra o launcher do Noctalia, digite `/pl` e continue digitando para filtrar pelo nome da instância. Ao ativar um resultado, o provider executa o FreeSM Flatpak com `--launch` e o identificador da instância.

Se o FreeSM estiver configurado para um Launcher Root diferente, ajuste `prism_path` em Settings → Plugins → FreeSM Launcher Instances. A alteração deve apontar para o diretório que contém `instances/` e os arquivos de configuração do launcher.

## Segurança e escopo

A configuração usa o comando Flatpak como default para não depender de um binário `prismlauncher` nativo no `PATH`. O plugin não cria conta, altera configurações, baixa conteúdo ou modifica os arquivos do FreeSM; apenas enumera instâncias e solicita o lançamento da selecionada.
