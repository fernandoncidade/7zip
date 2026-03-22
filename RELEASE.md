# Release Notes: 7-Zip Fork

**Version / Versão:** 2026.3.19.0  
**Author / Autor:** Fernando Nillsson Cidade

## Languages

- [Português](#português)
- [English](#english)

---

## Português

# Notas de Lançamento: 7-Zip Fork

**Versão:** 2026.3.19.0  
**Autor:** Fernando Nillsson Cidade

## Resumo técnico da release

Esta release consolida alterações estruturais e funcionais relevantes sobre a base do 7-Zip, com foco principal na expansão do fluxo de compressão pela GUI, customização institucional do fork, reorganização do pipeline de build, sincronização local dos idiomas, geração local do instalador e fortalecimento do ciclo de desinstalação.

Do ponto de vista arquitetural, a versão `2026.3.19.0` altera diretamente estes subsistemas:

- interface de compressão da GUI
- backend de roteamento de operações de atualização e compressão
- diálogo `Sobre o 7-Zip`
- mecanismo de localização e sincronização de idiomas
- pipeline de build do File Manager e do instalador
- instalador e metadados persistidos no Windows
- desinstalador e limpeza de DLLs e artefatos temporários

## Escopo da release

### Componentes impactados

- `CPP/7zip/UI/GUI/CompressDialog.cpp`
- `CPP/7zip/UI/GUI/CompressDialog.h`
- `CPP/7zip/UI/GUI/CompressDialog.rc`
- `CPP/7zip/UI/GUI/CompressDialogRes.h`
- `CPP/7zip/UI/GUI/UpdateGUI.cpp`
- `CPP/7zip/UI/Common/Update.h`
- `CPP/7zip/UI/FileManager/AboutDialog.cpp`
- `CPP/7zip/UI/FileManager/AboutDialog.rc`
- `CPP/7zip/UI/FileManager/AboutDialogRes.h`
- `CPP/7zip/UI/FileManager/LangUtils.cpp`
- `C/Util/7zipInstall/7zipInstall.c`
- `C/Util/7zipUninstall/7zipUninstall.c`
- `CPP/7zip/Bundles/Fm/makefile`
- `CPP/7zip/UI/GUI/makefile`
- `CPP/Build.mak`
- `.vscode/7zip-installer-task.ps1`
- `Lang/*`
- `InstallerAssets/*`

## Alterações funcionais consolidadas

### 1. Expansão da janela `Adicionar ao arquivo compactado`

O fluxo de compressão da GUI foi ampliado para permitir cenários multi-item e multi-destino dentro do mesmo diálogo, sem exigir uma etapa externa de mapeamento manual.

#### 1.1 Grupos independentes por item selecionado

Quando múltiplos arquivos ou diretórios são selecionados na GUI principal e o usuário aciona `Adicionar`, o diálogo passa a construir um grupo lógico por item selecionado. Cada grupo mantém isolamento de estado e de widgets, incluindo:

- identificação visual do item de origem
- controle individual da quantidade de saídas
- campos independentes de caminho de saída
- persistência local do nome base do item selecionado

Essa alteração substitui a lógica anterior, que operava sobre uma única coleção agregada, por um modelo de grupos independentes associados diretamente ao item de origem.

#### 1.2 Múltiplas saídas por grupo

Cada grupo suporta até 5 saídas de empacotamento. Para isso, a camada de recursos e a camada de diálogo foram alteradas para instanciar múltiplos campos `Arquivo` e múltiplos botões `...`, mantendo sincronização entre estado visual e estado interno.

Comportamento consolidado:

- a primeira saída do grupo é inicializada com o caminho padrão sugerido
- as saídas adicionais permanecem vazias até ação explícita do usuário
- mudanças em `Quantidade` redimensionam o conjunto efetivamente ativo de saídas
- a navegação por `...` atua sobre a linha correta do grupo correspondente

Essa alteração elimina o comportamento anterior em que saídas adicionais herdavam indevidamente o mesmo caminho inicial do primeiro item.

#### 1.3 Layout dinâmico em runtime

O diálogo deixa de trabalhar com uma reserva fixa de espaço para cinco saídas sempre visíveis. A janela agora ajusta a disposição vertical dos controles conforme:

- número de grupos carregados
- quantidade de saídas habilitadas em cada grupo
- necessidade de exibir ou ocultar linhas extras

Na prática, houve reestruturação do cálculo de posicionamento, da altura do diálogo e da visibilidade dos widgets associados a cada linha de saída.

#### 1.4 Correções de geração de nome e extensão

O fluxo de composição do nome do arquivo compactado foi corrigido para resolver inconsistências de normalização de extensão, especialmente em cenários com nomes já terminados no sufixo do formato corrente.

Problemas corrigidos:

- `Download.7z.7z`
- `.7z..7z`
- nomes vazios derivados de diretórios com barra final
- reaplicação indevida de extensão quando o formato era alterado

Também foi ajustada a lógica de atualização dos caminhos extras para que linhas vazias não passem a receber extensões automaticamente.

### 2. Ajustes no backend de compressão

O backend que prepara e dispara as operações de compressão foi expandido para receber o novo modelo de saídas por grupo e por item.

#### 2.1 Propagação de estado entre GUI e camada de atualização

O conjunto de opções transportado entre o diálogo e o backend foi estendido para suportar:

- múltiplos caminhos por grupo
- associação entre item selecionado e saídas correspondentes
- preservação do comportamento legado quando a operação continua sendo simples

Os principais pontos de integração dessa consolidação foram:

- `CPP/7zip/UI/GUI/UpdateGUI.cpp`
- `CPP/7zip/UI/Common/Update.h`

#### 2.2 Correção de reaplicação indevida de extensão

O fluxo do File Manager que originalmente entrava com modo de nome automático passou a respeitar corretamente caminhos já explicitados na GUI, evitando dupla reaplicação de extensão em operações confirmadas pelo usuário.

### 3. Customização da janela `Sobre o 7-Zip`

O diálogo `Sobre o 7-Zip` foi expandido para preservar o bloco institucional original do projeto e adicionar um bloco institucional do fork, com identidade própria do mantenedor.

#### 3.1 Conteúdo adicional incorporado

O diálogo agora incorpora:

- observação de que a build refere-se a um fork
- identificação da versão do fork
- data de referência do fork
- copyright específico do autor
- link para o repositório do fork
- manutenção da linha informando que o 7-Zip é software grátis

#### 3.2 Integração com recursos e runtime

As alterações envolveram:

- aumento e reorganização do layout do recurso `.rc`
- novos controles dedicados no diálogo
- resolução de textos por idioma
- fallback seguro para strings padrão quando necessário
- tratamento do link do repositório como ação clicável

### 4. Sistema de idiomas e localização

O fork consolida `Lang/` na raiz do repositório como a fonte principal de verdade dos arquivos de idioma utilizados na GUI, no File Manager local e no stage do instalador.

#### 4.1 Novas entradas de idioma

Foram incorporadas novas chaves e novos blocos de tradução para suportar:

- o rótulo `Quantidade`
- o conteúdo expandido da janela `Sobre`
- a linha de repositório do fork

Na prática, o rótulo `Quantidade` foi associado ao ID `4021`, enquanto o bloco `2900` passou a acomodar a expansão das informações exibidas no diálogo `Sobre`.

#### 4.2 Normalização dos arquivos de idioma

Foi implementado um fluxo de normalização para evitar que a aba `Language` da GUI acuse erros como `Error in Lang file`.

Os principais cuidados adotados foram:

- inserção ordenada dos IDs
- remoção de duplicidades inválidas
- preservação da estrutura esperada pelo parser do 7-Zip
- sincronização automática entre raiz `Lang/` e diretórios de runtime

#### 4.3 Cobertura ampliada de idiomas

Os idiomas presentes no projeto passaram a receber suporte para os novos elementos da janela `Sobre` e para o rótulo `Quantidade`, com sincronização para:

- `CPP/7zip/UI/FileManager/x64/Lang`
- `CPP/7zip/Bundles/Fm/x64/Lang`
- `dist/installer-full/stage/Lang`

### 5. Reorganização do pipeline de build e do instalador

O pipeline do instalador foi redesenhado para deixar de depender do download do instalador oficial como base de montagem.

#### 5.1 Substituição do modelo baseado em download

Antes, o fluxo de empacotamento dependia de:

- download do instalador oficial
- extração de payload externo
- sobreposição posterior de binários locais

Agora, o `stage` do instalador passa a ser montado localmente a partir de:

- binários compilados no workspace
- ativos estáticos versionados no repositório
- base local de idiomas
- documentação local do projeto

#### 5.2 Introdução de ativos locais do instalador

Os arquivos antes obtidos da extração do instalador oficial foram movidos para o repositório, com uso direto a partir de:

- `InstallerAssets/7-zip.chm`
- `InstallerAssets/History.txt`
- `InstallerAssets/descript.ion`

#### 5.3 Saída final renomeada do instalador

O artefato final gerado por este fork passa a ser:

- `dist/7z2026.3.19.0-x64.exe`

Isso substitui o nome padronizado anterior derivado da versão upstream.

### 6. Personalização do instalador e do Painel de Controle

O instalador foi ajustado para registrar metadados próprios do fork no Windows.

#### 6.1 Metadados de registro alterados

Ao instalar o produto, a chave de desinstalação passa a gravar:

- `DisplayName = 7-Zip 2026.3.19.0 (x64)`
- `DisplayVersion = 2026.3.19.0`
- `Publisher = Fernando Nillsson Cidade`

Esses dados são persistidos na entrada:

- `Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\7-Zip`

#### 6.2 Coerência entre binário, instalador e identidade visual

A release alinha:

- nome do instalador
- versão apresentada ao usuário
- identidade do fork na janela `Sobre`
- metadados exibidos pelo Painel de Controle

### 7. Fortalecimento do desinstalador

O subsistema de remoção foi endurecido para reduzir sobras pós-desinstalação e para evitar comportamento agressivo sobre o Windows Explorer.

#### 7.1 Limpeza explícita de arquivos temporários

O desinstalador passou a tratar de forma explícita sobras como:

- `7-zip.dll.tmp`
- variantes temporárias correlatas

#### 7.2 Elevação administrativa e remoção mais segura

O fluxo agora tenta operar com privilégios apropriados quando necessário, evitando falhas silenciosas na remoção de arquivos instalados em diretórios protegidos do sistema.

#### 7.3 Correção da estratégia de remoção de DLLs em uso

Uma solução intermediária baseada em encerramento amplo de processos do Explorer mostrou-se intrusiva, pois podia fechar janelas do Explorador de Arquivos e afetar temporariamente a barra de tarefas. A implementação consolidada substitui esse comportamento por uma estratégia menos agressiva de descarregamento da shell extension, preservando o ambiente do usuário.

Resultado esperado:

- menos sobras de DLLs
- menor necessidade de reinicialização
- ausência do efeito colateral de fechar globalmente o Explorer

### 8. Robustez de build incremental

Foram incluídas correções de dependência para evitar composições inválidas entre objetos antigos e cabeçalhos novos, bem como para garantir a regeneração de recursos quando arquivos `.rc` são alterados.

#### 8.1 Ajustes aplicados

- dependências explícitas para módulos que consomem `CompressDialog.h`
- dependências explícitas para módulos que consomem `Update.h`
- dependências explícitas de `AboutDialog.rc` e `AboutDialogRes.h` para regeneração de `resource.res`
- sincronização automática das bases locais de idioma usadas pelos binários de teste

#### 8.2 Benefícios práticos

Essas alterações reduzem falhas como:

- fechamento inesperado do `7zFM.exe` após mudança estrutural de diálogo
- binários relincados com recursos antigos
- runtime carregando idiomas desatualizados

## Impacto técnico por subsistema

### GUI de compressão

- novo modelo de grupos por item
- novo modelo de múltiplas saídas por grupo
- layout recalculado em runtime
- correção de normalização de nomes e extensões

### Backend de update e compressão

- expansão da estrutura de opções
- repasse correto dos caminhos configurados pela GUI
- preservação de compatibilidade com fluxo simples

### Recursos e localização

- expansão de recursos `.rc`
- adição de novos IDs
- sincronização de idioma raiz para runtime
- normalização automática dos arquivos de tradução

### Instalador

- geração local do `stage`
- uso de ativos versionados no próprio repositório
- nome final do instalador alinhado à identidade do fork
- metadados do produto customizados no Windows

### Desinstalador

- limpeza reforçada de arquivos temporários
- remoção mais segura de DLLs
- comportamento menos intrusivo sobre shell e Explorer

## Artefatos relevantes desta release

- `CPP/7zip/UI/FileManager/x64/7zFM.exe`
- `CPP/7zip/Bundles/Fm/x64/7zFM.exe`
- `dist/7z2026.3.19.0-x64.exe`
- `Lang/*`
- `InstallerAssets/*`

## Compatibilidade e observações operacionais

- a base upstream do 7-Zip foi preservada, com extensões direcionadas principalmente ao File Manager e ao pipeline local de build e instalação
- a nova lógica de compressão afeta principalmente o fluxo acionado pela GUI `Adicionar ao arquivo compactado`
- a coerência visual e institucional do fork depende da sincronização correta entre recursos, idiomas e binários locais
- a normalização de `Lang/` deve continuar sendo executada pelo script de build para evitar regressões na aba `Language`

## Resultado consolidado

A release `7-Zip Fork 2026.3.19.0` transforma o projeto em uma variante operacionalmente mais orientada a fluxos avançados de empacotamento, com suporte nativo a múltiplos destinos por item, identidade institucional do fork, pipeline de distribuição autocontido, cobertura de localização ampliada e ciclo de instalação e desinstalação mais controlado.

## Complemento da release `2026.3.22.0`

Esta seção complementa as notas históricas da versão `2026.3.19.0` com ajustes adicionais consolidados na branch como versão `2026.3.22.0`, sem substituir o conteúdo anterior.

### Título sugerido

`Remove incomplete Paths dialog and add LangUtils IntelliSense fallback`

### Descrição

Este commit remove o fluxo inacabado de UI do botão `Paths...` da janela de compressão e mantém as linhas já existentes de caminhos de saída como único fluxo suportado para múltiplos destinos de arquivo.

### Alterações técnicas

- remoção do botão `Paths...` do recurso da janela de compressão;
- remoção da declaração e da implementação do handler `OnButtonOutputPaths()`;
- remoção da classe auxiliar `COutputArcPathsDialog`;
- remoção dos IDs de recurso dedicados e da dialog associada a `IDD_COMPRESS_OUTPUT_PATHS`;
- remoção das rotinas auxiliares de parsing/serialização usadas exclusivamente por essa dialog;
- `OutputPathsToText()`;
- `TextToOutputPaths()`;
- `OutputItemArcPathsToText()`;
- `TextToOutputItemArcPaths()`;
- helpers relacionados à exibição e à resolução de itens.

### Motivação

- a dialog não fazia parte de um fluxo finalizado;
- a janela principal de compressão já expõe múltiplos destinos de saída por meio do seletor de quantidade, dos campos de caminho de arquivo e dos botões de browse já existentes;
- manter uma segunda superfície para edição desses caminhos duplicaria a lógica de UI/estado e aumentaria o custo de manutenção sem acrescentar funcionalidade estável.

### Impacto comportamental

- nenhuma lógica de formato de arquivo foi alterada;
- nenhum comportamento do backend de compressão/atualização foi alterado;
- o usuário continua configurando múltiplos destinos de saída pelos controles de caminho já existentes na própria janela de compressão.

### Ajuste adicional em `LangUtils.h`

Além disso, este commit adiciona um fallback para `LangString_OnlyFromLangFile()` quando `Z7_LANG` não está definido.

#### Justificativa técnica

- `CompressDialog.cpp` chama `LangString_OnlyFromLangFile()`;
- o símbolo só era declarado quando `Z7_LANG` estava definido;
- em algumas configurações de IDE/IntelliSense, `Z7_LANG` não fica visível para o parser, o que gerava um diagnóstico falso de “identificador não definido”, mesmo quando a configuração real de build fornecia o símbolo.

O novo fallback inline mantém a interface do header consistente entre diferentes configurações, retornando string vazia quando a busca exclusiva por arquivo de idioma não está disponível. Isso não altera o comportamento esperado em builds localizados normais; apenas elimina a inconsistência percebida por análise estática e IntelliSense.

## Autoria

**Fernando Nillsson Cidade**

---

## English

# Release Notes: 7-Zip Fork

**Version:** 2026.3.19.0  
**Author:** Fernando Nillsson Cidade

## Technical release summary

This release consolidates a set of structural and functional changes on top of the 7-Zip codebase, with primary focus on expanding the GUI compression workflow, establishing fork-specific product identity, reorganizing the build pipeline, synchronizing local language assets, producing the installer locally, and strengthening the uninstall lifecycle.

From an architectural perspective, version `2026.3.19.0` directly affects these subsystems:

- GUI compression interface
- update and compression backend routing
- `About 7-Zip` dialog
- language lookup and synchronization mechanism
- File Manager and installer build pipeline
- installer and Windows product metadata
- uninstaller and cleanup of DLLs and temporary artifacts

## Release scope

### Impacted components

- `CPP/7zip/UI/GUI/CompressDialog.cpp`
- `CPP/7zip/UI/GUI/CompressDialog.h`
- `CPP/7zip/UI/GUI/CompressDialog.rc`
- `CPP/7zip/UI/GUI/CompressDialogRes.h`
- `CPP/7zip/UI/GUI/UpdateGUI.cpp`
- `CPP/7zip/UI/Common/Update.h`
- `CPP/7zip/UI/FileManager/AboutDialog.cpp`
- `CPP/7zip/UI/FileManager/AboutDialog.rc`
- `CPP/7zip/UI/FileManager/AboutDialogRes.h`
- `CPP/7zip/UI/FileManager/LangUtils.cpp`
- `C/Util/7zipInstall/7zipInstall.c`
- `C/Util/7zipUninstall/7zipUninstall.c`
- `CPP/7zip/Bundles/Fm/makefile`
- `CPP/7zip/UI/GUI/makefile`
- `CPP/Build.mak`
- `.vscode/7zip-installer-task.ps1`
- `Lang/*`
- `InstallerAssets/*`

## Consolidated functional changes

### 1. `Add to Archive` dialog expansion

The GUI compression flow was expanded to support both multi-item and multi-destination scenarios within the same dialog, without requiring an external manual mapping step.

#### 1.1 Independent groups per selected item

When multiple files or directories are selected in the main GUI and the user triggers `Add`, the dialog now creates one logical group per selected item. Each group maintains isolated state and widgets, including:

- visual identification of the source item
- per-group output quantity control
- independent output path fields
- local persistence of the selected item's base name

This change replaces the previous model, which operated over a single aggregated collection, with a structure of independent groups directly associated with the source item.

#### 1.2 Multiple outputs per group

Each group supports up to 5 archive outputs. To enable this, both the resource layer and the dialog layer were expanded to instantiate multiple `Archive` fields and multiple `...` buttons while keeping the visual state synchronized with the internal state.

Consolidated behavior:

- the first group output is initialized with the suggested default path
- additional outputs remain blank until explicit user action
- changes to `Quantity` resize the active set of outputs
- the `...` browser acts on the correct line inside the corresponding group

This removes the previous behavior where extra outputs incorrectly inherited the same initial path from the first item.

#### 1.3 Dynamic runtime layout

The dialog no longer reserves a fixed block of space for five always-visible outputs. Instead, the window now adapts its vertical layout according to:

- number of loaded groups
- number of enabled outputs in each group
- whether extra lines need to be shown or hidden

In practical terms, this required restructuring control positioning, dialog height calculation, and visibility handling for widgets tied to each output line.

#### 1.4 File name and extension generation fixes

The archive name composition flow was corrected to resolve extension normalization issues, especially in cases where the user-provided name already ended with the current format suffix.

Fixed issues:

- `Download.7z.7z`
- `.7z..7z`
- empty names derived from directories with trailing separators
- incorrect extension reapplication when the format changed

The extra-output update flow was also adjusted so that blank lines do not receive artificial extensions automatically.

### 2. Compression backend adjustments

The backend responsible for preparing and dispatching compression operations was expanded to accept the new model of outputs per group and per item.

#### 2.1 State propagation between GUI and update layer

The options structure transported between the dialog and the backend was extended to support:

- multiple paths per group
- association between selected items and their corresponding outputs
- preservation of legacy behavior when the operation remains simple

The main integration points for this consolidation were:

- `CPP/7zip/UI/GUI/UpdateGUI.cpp`
- `CPP/7zip/UI/Common/Update.h`

#### 2.2 Fix for incorrect extension reapplication

The File Manager flow that originally entered with automatic archive-name mode was adjusted to respect paths already made explicit in the GUI, preventing double extension reapplication after user confirmation.

### 3. `About 7-Zip` dialog customization

The `About 7-Zip` dialog was expanded to preserve the original project block while adding a fork-specific institutional block with maintainer identity.

#### 3.1 Additional content introduced

The dialog now includes:

- a note that the build refers to a fork
- fork version identification
- fork reference date
- author-specific copyright
- a link to the fork repository
- preservation of the line stating that 7-Zip is free software

#### 3.2 Integration with resources and runtime

The implementation involved:

- resizing and reorganizing the `.rc` dialog layout
- adding dedicated dialog controls
- resolving texts through language resources
- safe fallback to default strings when needed
- handling the repository entry as a clickable action

### 4. Language and localization system

The fork consolidates root `Lang/` as the single source of truth for language files consumed by the GUI, the local File Manager runtime, and the installer stage.

#### 4.1 New language entries

New translation keys and blocks were added to support:

- the `Quantity` label
- the expanded `About` dialog content
- the fork repository line

In practice, the `Quantity` label was bound to ID `4021`, while block `2900` was extended to accommodate the additional information displayed by the `About` dialog.

#### 4.2 Language file normalization

A normalization flow was implemented to prevent the GUI `Language` tab from reporting errors such as `Error in Lang file`.

Key safeguards included:

- ordered insertion of IDs
- removal of invalid duplicates
- preservation of the structure expected by the 7-Zip parser
- automatic synchronization between root `Lang/` and runtime language directories

#### 4.3 Expanded language coverage

Existing project languages now support the new `About` dialog elements and the `Quantity` label, with synchronization to:

- `CPP/7zip/UI/FileManager/x64/Lang`
- `CPP/7zip/Bundles/Fm/x64/Lang`
- `dist/installer-full/stage/Lang`

### 5. Build pipeline and installer reorganization

The installer pipeline was redesigned to remove the dependency on downloading the official installer as the assembly base.

#### 5.1 Replacing the download-based model

Previously, the packaging flow depended on:

- downloading the official installer
- extracting an external payload
- overlaying local binaries afterwards

Now, the installer `stage` is assembled locally from:

- binaries compiled in the workspace
- static assets versioned in the repository
- local language assets
- local project documentation

#### 5.2 Introduction of local installer assets

Files previously obtained from the extracted official installer were moved into the repository and are now consumed directly from:

- `InstallerAssets/7-zip.chm`
- `InstallerAssets/History.txt`
- `InstallerAssets/descript.ion`

#### 5.3 Renamed final installer output

The final artifact generated by this fork is now:

- `dist/7z2026.3.19.0-x64.exe`

This replaces the previous default name derived from the upstream release number.

### 6. Installer and Control Panel customization

The installer was adjusted to persist fork-specific product metadata in Windows.

#### 6.1 Modified registry metadata

When the product is installed, the uninstall key now writes:

- `DisplayName = 7-Zip 2026.3.19.0 (x64)`
- `DisplayVersion = 2026.3.19.0`
- `Publisher = Fernando Nillsson Cidade`

These values are stored at:

- `Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\7-Zip`

#### 6.2 Consistency across binary, installer, and visual identity

This release aligns:

- installer file name
- user-facing version string
- fork identity shown in the `About` dialog
- metadata displayed in Windows Control Panel

### 7. Uninstaller hardening

The removal subsystem was reinforced to reduce uninstall leftovers while avoiding aggressive behavior against Windows Explorer.

#### 7.1 Explicit cleanup of temporary files

The uninstaller now explicitly handles leftovers such as:

- `7-zip.dll.tmp`
- related temporary variants

#### 7.2 Administrative elevation and safer removal

The flow now attempts to operate with proper privileges when needed, avoiding silent failures while removing files installed under protected system directories.

#### 7.3 Fix for the DLL-in-use removal strategy

An intermediate solution based on broad Explorer process termination proved too intrusive because it could close File Explorer windows and temporarily affect the taskbar. The consolidated implementation replaces that behavior with a less aggressive shell-extension unload strategy that preserves the user environment.

Expected result:

- fewer leftover DLLs
- lower need for reboot fallback
- no side effect of globally closing Explorer

### 8. Incremental build robustness

Dependency corrections were added to avoid invalid combinations of old object files with newer headers and to guarantee resource regeneration whenever `.rc` files change.

#### 8.1 Applied adjustments

- explicit dependencies for modules consuming `CompressDialog.h`
- explicit dependencies for modules consuming `Update.h`
- explicit dependencies from `AboutDialog.rc` and `AboutDialogRes.h` to regenerate `resource.res`
- automatic synchronization of local language bases used by test binaries

#### 8.2 Practical benefits

These changes reduce issues such as:

- unexpected `7zFM.exe` termination after structural dialog changes
- relinking binaries with outdated resources
- runtime loading stale language files

## Technical impact by subsystem

### Compression GUI

- new per-item grouping model
- new multiple-output-per-group model
- runtime-recalculated layout
- file name and extension normalization fixes

### Update and compression backend

- expanded options structure
- proper propagation of GUI-configured output paths
- preserved compatibility with simple workflows

### Resources and localization

- expanded `.rc` resources
- new control/resource IDs
- synchronization from root language base to runtime
- automatic normalization of translation files

### Installer

- local stage generation
- use of repository-versioned assets
- final installer name aligned with fork identity
- custom product metadata in Windows

### Uninstaller

- stronger temporary-file cleanup
- safer DLL removal flow
- less intrusive shell and Explorer behavior

## Relevant artifacts in this release

- `CPP/7zip/UI/FileManager/x64/7zFM.exe`
- `CPP/7zip/Bundles/Fm/x64/7zFM.exe`
- `dist/7z2026.3.19.0-x64.exe`
- `Lang/*`
- `InstallerAssets/*`

## Compatibility and operational notes

- the upstream 7-Zip base was preserved, with extensions focused mainly on the File Manager and the local build/install pipeline
- the new compression logic primarily affects the GUI path driven by `Add to Archive`
- visual and institutional consistency of the fork depends on correct synchronization between resources, languages, and local binaries
- `Lang/` normalization should continue to be executed by the build script to avoid regressions in the `Language` tab

## Consolidated result

Release `7-Zip Fork 2026.3.19.0` turns the project into a variant more strongly oriented toward advanced packaging workflows, with native support for multiple output destinations per item, fork-specific product identity, a self-contained distribution pipeline, expanded localization coverage, and a more controlled installation and uninstallation cycle.

## Complementary update `2026.3.22.0`

This section complements the historical `2026.3.19.0` notes with additional changes consolidated in the branch as version `2026.3.22.0`, without replacing the previous content.

### Suggested title

`Remove incomplete Paths dialog and add LangUtils IntelliSense fallback`

### Suggested description

This commit removes the unfinished `Paths...` UI flow from the compression dialog and keeps the existing output-path rows as the only supported workflow for multiple archive destinations.

### Technical changes

- removed the `Paths...` button from the compression dialog resource;
- removed the `OnButtonOutputPaths()` handler declaration and implementation;
- removed the auxiliary `COutputArcPathsDialog` class;
- removed the dedicated resource IDs and dialog resource associated with `IDD_COMPRESS_OUTPUT_PATHS`;
- removed the helper parsing/serialization routines used exclusively by that dialog;
- `OutputPathsToText()`;
- `TextToOutputPaths()`;
- `OutputItemArcPathsToText()`;
- `TextToOutputItemArcPaths()`;
- related item display and resolution helpers.

### Rationale

- the dialog was not part of a finalized workflow;
- the main compression dialog already exposes multiple output destinations through the existing count selector, archive-path fields, and browse buttons;
- keeping a second surface for editing those paths would duplicate UI/state management and increase maintenance cost without adding stable functionality.

### Behavioral impact

- no archive format logic was changed;
- no compression/update backend behavior was changed;
- users still configure multiple output destinations through the existing archive-path controls already present in the compression dialog.

### Additional `LangUtils.h` adjustment

This commit also adds a fallback for `LangString_OnlyFromLangFile()` when `Z7_LANG` is not defined.

#### Technical rationale

- `CompressDialog.cpp` calls `LangString_OnlyFromLangFile()`;
- the symbol was only declared when `Z7_LANG` was defined;
- in some IDE/IntelliSense configurations, `Z7_LANG` is not visible to the parser, which caused a false “identifier is undefined” diagnostic even though the real build configuration provides the symbol.

The new inline fallback keeps the header interface consistent across configurations by returning an empty string when language-file-only lookup is unavailable. This does not change the intended behavior for normal localized builds; it only removes the configuration mismatch reported by static analysis and IntelliSense.

## Authorship

**Fernando Nillsson Cidade**
