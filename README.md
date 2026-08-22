# dms-conf

`dms-conf` é a camada opcional de manutenção de patches de primeira camada para o **DankMaterialShell** usado pelo desktop Livara. Ele não substitui a configuração declarativa em `nix-conf` nem os plugins e adapters de `shell-conf`.

## Contrato arquitetural

A separação de responsabilidades é deliberada:

| Camada | Responsabilidade | Alteração típica |
| --- | --- | --- |
| `nix-conf` | host, hardware, serviços, capacidades e composição do sistema | `dmsSettings`, widgets por capacidade, units e locks |
| `shell-conf` | API visual Livara, plugins, adapters e arquivos independentes do host | plugin QML, sincronização de temas e Fastfetch |
| `dms-conf` | patches pequenos e versionados no código upstream DMS | apenas comportamento ou geometria que a API pública não expõe |
| upstream DMS | templates, serviços e componentes nativos | fonte de verdade; não editar `/nix/store` |

O fluxo futuro será **opt-in**: enquanto não houver um patch aplicado e validado, `nix-conf` continua consumindo diretamente o input DMS v1.5.3. Um repositório vazio não deve ser usado como overlay no flake principal, pois isso criaria uma dependência sem comportamento definido e dificultaria a reprodutibilidade.

## Política de pin e patch

Cada patch deve ser aplicado sobre um commit upstream imutável, preferencialmente o commit já fixado pelo desktop (`069ddab041c738236a8910e4c39b65d9628d3018`). A atualização de versão deve ser uma mudança separada, acompanhada de nova auditoria dos contratos QML, dos nomes de settings e da interface de plugins.

A árvore prevista para a primeira implementação é:

```text
patches/
  0001-describe-purpose.patch
checks/
  qml-structure.sh
README.md
flake.nix
```

O patch deve ser pequeno, ter uma justificativa e indicar o arquivo upstream afetado. Não se deve copiar o DMS inteiro para `shell-conf`, duplicar templates nativos, ou editar arquivos materializados em `/nix/store`.

## Integração Nix futura

Quando o primeiro patch existir, este repositório deverá expor um overlay ou pacote derivado do input DMS pinado. A composição em `nix-conf` deve então ser explícita, por exemplo `dmsPackage = inputs.dms-conf.packages.${pkgs.system}.default`, e o `flake.lock` deve registrar o commit de `dms-conf` e seus inputs. Antes disso, não há razão para adicionar o repositório ao lock do sistema.

A integração deve preservar os inputs do DMS sempre que possível, evitando uma segunda cópia de `nixpkgs`, e deve incluir uma verificação leve que confirme que o patch aplica sobre a revisão pinada. Builds completos do desktop ficam para o host ou CI; a validação local desta tarefa deve permanecer em parse Nix, `git diff --check`, checks de shell e inspeção estrutural QML.

## Critérios para promover uma mudança a patch

Uma alteração só pertence a `dms-conf` se a necessidade for comprovadamente de primeira camada, se não houver setting ou plugin público compatível, e se ela puder ser isolada sem assumir hardware do host. Exemplos prováveis são geometria fixa do `WorkspaceSwitcher` e suporte de vídeo no wallpaper, mas ambos exigem prova de necessidade e uma implementação completa; GIF ou MP4 não devem ser anunciados como suportados apenas por alterar filtros de nomes.

Mudanças de paleta, adapters de aplicações, launcher, fastfetch, AudioRelay, Nautilus e detecção de mesa permanecem fora desta camada. Elas pertencem respectivamente a DMS/shell-conf, adapters, nix-conf ou aos repositórios específicos do recurso.

## Estado atual

O repositório começa conscientemente apenas com esta especificação. Nenhum patch foi inventado, nenhum overlay foi ativado e o DMS fixado em `nix-conf` não foi substituído. O primeiro commit de código deverá nascer somente depois de reproduzir o problema no DMS v1.5.3, comparar a API pública e adicionar uma validação para a revisão base.
