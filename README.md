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

A primeira implementação usa esta estrutura:

```text
patches/
  0001-livara-network-widget-on-ethernet.patch
  0002-livara-game-mode-power-action.patch
flake.nix
README.md
```

O pacote é derivado de `dms.lib.mkDmsShell` e aplica os patches depois que o upstream instala o código QML. O `homeModule` do dms-conf importa o módulo oficial e força `programs.dank-material-shell.package` para o derivado patchado. Nenhum arquivo do DMS é editado no `/nix/store` e o clone upstream permanece somente como fonte de comparação.

O patch deve ser pequeno, ter uma justificativa e indicar o arquivo upstream afetado. Não se deve copiar o DMS inteiro para `shell-conf`, duplicar templates nativos, ou editar arquivos materializados em `/nix/store`.

## Integração Nix futura

A composição em `nix-conf` agora é explícita: `dmsPackage = inputs.dms-conf.packages.${pkgs.system}.default` e `inputs.dms-conf.homeModules.dank-material-shell` substitui o módulo upstream no `sharedModules`. O `flake.lock` registra o commit de `dms-conf`; o input interno `dms` segue o input DMS já pinado do sistema, evitando uma segunda revisão.

A integração inclui o check `patches-apply`, que copia apenas a árvore QML do DMS pinado e confirma que os dois patches aplicam sem rejeições. Builds completos do desktop ficam para o host ou CI; a validação local permanece em parse Nix, `git diff --check`, aplicação estrutural dos patches e inspeção QML.

## Critérios para promover uma mudança a patch

Uma alteração só pertence a `dms-conf` se a necessidade for comprovadamente de primeira camada, se não houver setting ou plugin público compatível, e se ela puder ser isolada sem assumir hardware do host. Exemplos prováveis são geometria fixa do `WorkspaceSwitcher` e suporte de vídeo no wallpaper, mas ambos exigem prova de necessidade e uma implementação completa; GIF ou MP4 não devem ser anunciados como suportados apenas por alterar filtros de nomes.

Mudanças de paleta, adapters de aplicações, launcher, fastfetch, AudioRelay, Nautilus e detecção de mesa permanecem fora desta camada. Elas pertencem respectivamente a DMS/shell-conf, adapters, nix-conf ou aos repositórios específicos do recurso.

## Estado atual

O repositório contém agora dois patches opt-in aplicados pelo pacote: o widget Network passa a ser habilitado por `NetworkService.networkAvailable`, permitindo Ethernet no host sem Wi-Fi; e o PowerMenu recebe uma ação Game/Normal condicionada às variáveis `LIVARA_DMS_GAME_MODE` e `LIVARA_DMS_GAMEMODE_CONTROL`. O segundo patch não altera os três perfis nativos do PowerProfiles e não aparece no Latitude.

O botão Game é implementado como request de GameMode mantido por um serviço de usuário do myMachine. O backend em `nix-conf` usa `gamemoded -r`, lê estado via `systemctl --user is-active` e libera a requisição com `SIGINT`; GameMode permanece semanticamente separado de `power-profiles-daemon`.

Nautilus, Fastfetch/Roxy, AudioRelay, Matugen/adapters e detecção da mesa continuam fora do dms-conf. Em particular, GIO metadata já corrige o ícone da pasta no conteúdo do Nautilus, mas a sidebar de bookmarks usa ícones simbólicos conforme o contrato upstream; um patch de bookmark deve nascer no repositório do Nautilus, não ser escondido dentro do DMS.
