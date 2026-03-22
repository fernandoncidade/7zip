# 7-Zip Fork 2026.3.22.0

Fork customizado do 7-Zip, desenvolvido para consolidar melhorias funcionais, visuais e operacionais sobre a base do projeto original.

Custom 7-Zip fork created to consolidate functional, visual, and operational improvements on top of the original project.

Projeto upstream: [7-zip.org](https://7-zip.org)  
Fork repository: <https://github.com/fernandoncidade/7zip/tree/simultaneous_multiple_packaging?tab=readme-ov-file>

## Languages

- [Português](#portugues)
- [English](#english)

---

## Português

## Visão geral

Este repositório reúne um fork do 7-Zip com foco em ampliar o fluxo de empacotamento pela GUI, personalizar a identidade do projeto, consolidar a geração do instalador com ativos locais e melhorar a manutenção do build e da desinstalação.

## Objetivos deste fork

- permitir múltiplos caminhos de saída em uma única operação de compressão
- permitir múltiplos grupos independentes na janela `Adicionar ao arquivo compactado`
- manter identidade própria do fork na janela `Sobre`, no instalador e no Painel de Controle
- usar `Lang\` na raiz como base principal de traduções
- gerar o instalador localmente sem depender do download do instalador oficial
- tornar o processo de desinstalação mais limpo e menos intrusivo

## Implementações consolidadas

### 1. Janela `Adicionar ao arquivo compactado`

A interface de compressão foi ampliada para suportar cenários multi-saída e multi-item de forma nativa.

#### Múltiplas saídas por grupo

- o campo `Quantidade` define quantos caminhos de saída o grupo terá
- cada saída possui seu próprio campo `Arquivo` e seu próprio botão `...`
- o grupo suporta até 5 saídas
- apenas a primeira saída nasce preenchida com o caminho sugerido
- saídas adicionais passam a nascer vazias para preenchimento manual
- isso corrige o comportamento de replicar automaticamente `Download.7z` para todas as linhas extras

#### Grupos independentes por item selecionado

- quando o usuário seleciona mais de um arquivo ou pasta na GUI principal e clica em `Adicionar`, a janela de compressão abre um grupo por item selecionado
- cada grupo possui:
  - identificação do item de origem
  - campo `Quantidade`
  - conjunto próprio de campos `Arquivo`
- exemplo:
  - `D:\DOWNLOADS\Download`
  - `D:\DOWNLOADS\teams-files-2026-03-19`
  - a janela abre dois grupos independentes, um para cada item

#### Layout dinâmico em tempo de execução

- a altura da janela se ajusta conforme a quantidade de saídas habilitadas
- a interface deixa de reservar espaço fixo para cinco linhas o tempo todo
- ao aumentar ou reduzir a `Quantidade`, os controles são reposicionados dinamicamente

#### Regras e validações

- a primeira saída continua usando o caminho padrão sugerido
- saídas extras não são preenchidas automaticamente
- o sistema valida inconsistências entre caminhos antes de concluir a operação
- mudanças de formato e SFX atualizam os nomes de forma segura sem preencher linhas vazias artificialmente

#### Correções de nomes e extensões

- correção do problema `Download.7z.7z`
- correção do problema inicial `.7z..7z`
- correção do tratamento de diretórios com barra final
- atualização segura de extensões quando o formato muda
- preservação correta do nome-base do item selecionado

### 2. Janela `Sobre o 7-Zip`

A janela `Sobre o 7-Zip` foi customizada para manter as informações originais do projeto e incluir a identidade do fork.

Ela passou a exibir:

- bloco original do 7-Zip
- observação informando que esta versão refere-se a um fork customizado
- identificação de versão do fork
- data do fork
- copyright do desenvolvedor
- linha de repositório do fork
- linha final informando que o 7-Zip é software grátis

Conteudo adicional exibido:

- `Esta versão refere-se a um fork, customizado para atender as necessidades do desenvolvedor abaixo.`
- `7-Zip 2026.3.22.0 (x64)`
- `22/03/2026`
- `Copyright (c) 2026 Fernando Nillsson Cidade`
- `Repositório: https://github.com/fernandoncidade/7zip/tree/simultaneous_multiple_packaging?tab=readme-ov-file`
- `O 7-Zip é um software grátis`

### 3. Idiomas e localização

O sistema de idiomas foi reorganizado para adotar `Lang\` na raiz do repositório como fonte principal de verdade.

#### Estrutura adotada

- `Lang\` na raiz é a base canônica de idiomas
- as cópias usadas em runtime são sincronizadas para:
  - `CPP\7zip\Bundles\Fm\x64\Lang`
  - `CPP\7zip\UI\FileManager\x64\Lang`
  - `dist\installer-full\stage\Lang`

#### Entradas novas de tradução

- `4021`: tradução de `Quantidade`
- bloco `2900`: extensão do conteúdo da janela `Sobre`

#### Ajustes realizados

- inclusão das novas traduções para a interface expandida
- normalização dos arquivos para evitar `Error in Lang file`
- sincronização automática dos diretórios de idioma usados em runtime
- alinhamento entre a janela `Sobre` e os arquivos `Lang`

### 4. Pipeline de build e geração do instalador

O fluxo de empacotamento foi reorganizado para produzir o instalador localmente, sem depender do download do instalador oficial.

#### O que mudou

- `dist\` passou a ser o diretório principal de saída
- o `stage` do instalador é montado a partir dos binários compilados localmente
- o processo deixou de depender de `Invoke-WebRequest` e da extração do instalador oficial
- arquivos estáticos passaram a ser obtidos do próprio repositório

#### Fontes locais usadas

- `InstallerAssets\7-zip.chm`
- `InstallerAssets\History.txt`
- `InstallerAssets\descript.ion`
- `DOC\License.txt`
- `DOC\readme.txt`
- `Lang\*`
- binários compilados localmente

#### Saída final do instalador

O build deste fork gera:

- `dist\7z2026.3.22.0-x64.exe`

### 5. Metadados no Painel de Controle

Ao instalar o pacote gerado por este fork, a entrada do Windows passa a exibir:

- Nome: `7-Zip 2026.3.22.0 (x64)`
- Editor: `Fernando Nillsson Cidade`
- Versão: `2026.3.22.0`

Esses dados são gravados pelo instalador na chave:

- `Software\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip`

### 6. Desinstalador

O desinstalador foi ajustado para melhorar a remoção dos arquivos do produto, com foco especial nas DLLs usadas pelo shell.

#### Melhorias aplicadas

- limpeza explícita de arquivos temporários como `7-zip.dll.tmp`
- tentativa de elevação administrativa quando necessário
- descarregamento menos intrusivo da shell extension
- remoção mais segura de DLLs em uso
- preservação do Windows Explorer, evitando fechamento global das janelas e desaparecimento temporário da barra de tarefas

#### Comportamento esperado

- desinstalação mais limpa
- menor chance de sobras após remoção
- fallback para reinicialização apenas quando realmente necessário

### 7. Robustez do build local

Foram adicionados ajustes para reduzir problemas de build incremental inconsistente.

#### Consolidações feitas

- dependências explícitas entre `CompressDialog`, `UpdateGUI` e `Update.h`
- dependências explícitas de `AboutDialog.rc` e `AboutDialogRes.h` para regenerar `resource.res`
- espelhamento do `7zFM.exe` final para `CPP\7zip\UI\FileManager\x64\7zFM.exe`
- sincronização automática dos idiomas usados pelos binários locais

Isso reduz cenários como:

- alteração de recurso `.rc` sem refletir no binário
- relink com objetos antigos e cabeçalhos novos
- uso de diretórios `Lang` desatualizados ao lado do executável

## Estrutura relevante do projeto

- `CPP\`
  - código-fonte principal do 7-Zip
- `C\Util\7zipInstall\`
  - instalador
- `C\Util\7zipUninstall\`
  - desinstalador
- `Lang\`
  - base principal de idiomas
- `InstallerAssets\`
  - arquivos estáticos do instalador
- `DOC\`
  - documentação empacotada
- `dist\`
  - saída final de build e distribuição

## Como gerar o projeto

O fluxo principal de build do instalador está no script:

- `.vscode\7zip-installer-task.ps1`

### Ações disponíveis

- `build`
  - compila os binários, monta o stage e gera o instalador
- `run`
  - executa o instalador já gerado
- `build-run`
  - compila e executa
- `sync-lang`
  - normaliza e sincroniza os arquivos de idioma

### Exemplo

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .vscode\7zip-installer-task.ps1 build
```

## Resultado consolidado deste fork

Este fork entrega um 7-Zip com:

- múltiplas saídas por compressão
- grupos independentes por item selecionado
- interface adaptativa em tempo de execução
- identidade própria na janela `Sobre`, no instalador e no sistema
- suporte de idioma para os novos elementos da interface
- instalador gerado localmente
- metadados personalizados no Painel de Controle
- desinstalador mais seguro
- fluxo de build mais confiável para manutenção local

## Créditos

- Projeto original: Igor Pavlov
- Fork e customizações deste repositório: Fernando Nillsson Cidade

---

## English

## Overview

This repository contains a 7-Zip fork focused on expanding the GUI compression workflow, customizing project identity, consolidating installer generation with local assets, and improving build and uninstall maintenance.

## Goals of this fork

- allow multiple output paths in a single compression operation
- allow multiple independent groups inside the `Add to Archive` window
- keep a custom fork identity in the About dialog, installer, and Control Panel entry
- use root `Lang\` as the main translation source
- generate the installer locally without depending on the official installer download
- make uninstall behavior cleaner and less intrusive

## Consolidated implementations

### 1. `Add to Archive` window

The compression interface was extended to support multi-output and multi-item workflows natively.

#### Multiple outputs per group

- the `Quantity` field defines how many output paths a group will have
- each output has its own `Archive` field and its own `...` button
- each group supports up to 5 outputs
- only the first output is prefilled with the suggested default path
- additional outputs start blank and ready for manual input
- this fixes the previous behavior where `Download.7z` was duplicated to all extra lines

#### Independent groups per selected item

- when the user selects more than one file or folder in the main GUI and clicks `Add`, the compression window opens one group per selected item
- each group has:
  - source item identification
  - `Quantity`
  - its own `Archive` fields
- example:
  - `D:\DOWNLOADS\Download`
  - `D:\DOWNLOADS\teams-files-2026-03-19`
  - the dialog opens two independent groups, one for each item

#### Dynamic runtime layout

- the window height adapts to the number of enabled outputs
- the UI no longer reserves space for five fixed lines all the time
- when `Quantity` changes, controls are repositioned dynamically

#### Rules and validations

- the first output keeps using the suggested default path
- extra outputs are not auto-filled
- the system validates conflicting paths before completing the operation
- format and SFX changes update names safely without artificially filling empty lines

#### Name and extension fixes

- fixed `Download.7z.7z`
- fixed the initial `.7z..7z`
- fixed directory names with trailing separators
- safely updates extensions when format changes
- preserves the correct base name of the selected item

### 2. `About 7-Zip` window

The `About 7-Zip` dialog was customized to preserve the original project information while adding the fork identity.

It now displays:

- the original 7-Zip block
- a note explaining that this build is a customized fork
- fork version identification
- fork date
- developer copyright
- fork repository line
- a final line stating that 7-Zip is free software

Additional fork content:

- `This version refers to a fork customized to meet the needs of the developer below.`
- `7-Zip 2026.3.22.0 (x64)`
- `22/03/2026`
- `Copyright (c) 2026 Fernando Nillsson Cidade`
- `Repository: https://github.com/fernandoncidade/7zip/tree/simultaneous_multiple_packaging?tab=readme-ov-file`
- `7-Zip is free software`

### 3. Languages and localization

The language system was reorganized so that root `Lang\` becomes the primary source of truth.

#### Adopted structure

- root `Lang\` is the canonical language base
- runtime copies are synchronized to:
  - `CPP\7zip\Bundles\Fm\x64\Lang`
  - `CPP\7zip\UI\FileManager\x64\Lang`
  - `dist\installer-full\stage\Lang`

#### New translation entries

- `4021`: translation for `Quantity`
- `2900` block: extended content for the About dialog

#### Applied adjustments

- added translations for the expanded interface
- normalized language files to avoid `Error in Lang file`
- synchronized runtime language directories automatically
- aligned the About dialog content with `Lang` resources

### 4. Build pipeline and installer generation

The packaging flow was reorganized to produce the installer locally without relying on the official installer download.

#### What changed

- `dist\` became the main output directory
- the installer `stage` is assembled from locally compiled binaries
- the process no longer depends on `Invoke-WebRequest` or extracting the official installer
- static files now come from the repository itself

#### Local sources used by the installer

- `InstallerAssets\7-zip.chm`
- `InstallerAssets\History.txt`
- `InstallerAssets\descript.ion`
- `DOC\License.txt`
- `DOC\readme.txt`
- `Lang\*`
- locally compiled binaries

#### Final installer output

This fork now generates:

- `dist\7z2026.3.22.0-x64.exe`

### 5. Control Panel metadata

When the package generated by this fork is installed, the Windows entry shows:

- Name: `7-Zip 2026.3.22.0 (x64)`
- Publisher: `Fernando Nillsson Cidade`
- Version: `2026.3.22.0`

These values are written by the installer to:

- `Software\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip`

### 6. Uninstaller

The uninstaller was adjusted to improve product file removal, with special attention to shell-related DLLs.

#### Applied improvements

- explicit cleanup of temporary files such as `7-zip.dll.tmp`
- administrative elevation attempt when needed
- less intrusive shell extension unloading
- safer removal of DLLs in use
- preserves Windows Explorer behavior, avoiding global window shutdown and temporary taskbar disappearance

#### Expected behavior

- cleaner uninstall flow
- lower chance of leftovers after removal
- reboot fallback only when truly necessary

### 7. Local build robustness

Additional safeguards were added to reduce inconsistent incremental build issues.

#### Consolidated changes

- explicit dependencies between `CompressDialog`, `UpdateGUI`, and `Update.h`
- explicit dependencies from `AboutDialog.rc` and `AboutDialogRes.h` to regenerate `resource.res`
- mirroring of the final `7zFM.exe` to `CPP\7zip\UI\FileManager\x64\7zFM.exe`
- automatic synchronization of the language folders used by local test binaries

This helps avoid cases such as:

- `.rc` changes not being reflected in the final binary
- relinking old objects with new headers
- running local binaries with outdated `Lang` folders next to the executable

## Relevant project structure

- `CPP\`
  - main 7-Zip source code
- `C\Util\7zipInstall\`
  - installer
- `C\Util\7zipUninstall\`
  - uninstaller
- `Lang\`
  - main language base
- `InstallerAssets\`
  - local installer assets
- `DOC\`
  - packaged documentation
- `dist\`
  - final build and distribution output

## How to build

The main installer build flow is handled by:

- `.vscode\7zip-installer-task.ps1`

### Available actions

- `build`
  - compiles binaries, assembles the stage, and generates the installer
- `run`
  - runs the generated installer
- `build-run`
  - builds and runs
- `sync-lang`
  - normalizes and synchronizes language files

### Example

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .vscode\7zip-installer-task.ps1 build
```

## Consolidated result of this fork

This fork provides a 7-Zip build with:

- multiple outputs per compression operation
- independent groups per selected item
- runtime-adaptive UI behavior
- custom fork identity in the About dialog, installer, and system metadata
- language support for the new UI elements
- locally generated installer output
- customized Control Panel metadata
- safer uninstall behavior
- a more reliable local maintenance and build workflow

## Credits

- Original project: Igor Pavlov
- Fork and customizations in this repository: Fernando Nillsson Cidade
