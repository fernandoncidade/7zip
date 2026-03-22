param(
  [Parameter(Position = 0)]
  [ValidateSet("build", "run", "build-run", "sync-lang")]
  [string]$Action = "build-run"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ScriptDir ".."))

$VcVars64 = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$VcVarsAmd64X86 = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsamd64_x86.bat"

$ReleaseBuild = "2026.3.22.0"

$DistRoot = "D:\MISCELANEAS\VSCode\7zip\dist"
$WorkRoot = Join-Path $DistRoot "installer-full"
$StageDir = Join-Path $WorkRoot "stage"
$InstallerAssetsDir = Join-Path $RepoRoot "InstallerAssets"
$RepoDocsDir = Join-Path $RepoRoot "DOC"
$RepoLangDir = Join-Path $RepoRoot "Lang"
$PayloadArchive = Join-Path $WorkRoot "payload.7z"
$OutDir = $DistRoot
$OutputInstaller = Join-Path $OutDir "7z$ReleaseBuild-x64.exe"

function Assert-PathExists {
  param(
    [string]$Path,
    [string]$Label
  )

  if (-not (Test-Path $Path)) {
    throw "$Label nao encontrado: $Path"
  }
}

function Get-OutputInstallerPath {
  return $OutputInstaller
}

function Invoke-NMakeBuild {
  param(
    [string]$Label,
    [string]$WorkingDir,
    [string]$VcVarsPath,
    [string]$NMakeArgs = "nmake /nologo"
  )

  Assert-PathExists -Path $WorkingDir -Label $Label
  Assert-PathExists -Path $VcVarsPath -Label "vcvars"

  Write-Host "[7zip Installer] Compilando $Label..."
  $command = 'cd /d "' + $WorkingDir + '" && call "' + $VcVarsPath + '" >nul && ' + $NMakeArgs
  & cmd.exe /d /c $command
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

function Get-BuiltArtifacts {
  return @(
    @{ Name = "7z.exe"; Source = (Join-Path $RepoRoot "CPP\7zip\UI\Console\x64\7z.exe"); Destination = "7z.exe" },
    @{ Name = "7zG.exe"; Source = (Join-Path $RepoRoot "CPP\7zip\UI\GUI\x64\7zG.exe"); Destination = "7zG.exe" },
    @{ Name = "7zFM.exe"; Source = (Join-Path $RepoRoot "CPP\7zip\UI\FileManager\x64\7zFM.exe"); Destination = "7zFM.exe" },
    @{ Name = "7z.dll"; Source = (Join-Path $RepoRoot "CPP\7zip\Bundles\Format7zF\x64\7z.dll"); Destination = "7z.dll" },
    @{ Name = "7z.sfx"; Source = (Join-Path $RepoRoot "CPP\7zip\Bundles\SFXWin\x64\7z.sfx"); Destination = "7z.sfx" },
    @{ Name = "7zCon.sfx"; Source = (Join-Path $RepoRoot "CPP\7zip\Bundles\SFXCon\x64\7zCon.sfx"); Destination = "7zCon.sfx" },
    @{ Name = "7-zip.dll"; Source = (Join-Path $RepoRoot "CPP\7zip\UI\Explorer\x64\7-zip.dll"); Destination = "7-zip.dll" },
    @{ Name = "7-zip32.dll"; Source = (Join-Path $RepoRoot "CPP\7zip\UI\Explorer\x86\7-zip.dll"); Destination = "7-zip32.dll" },
    @{ Name = "Uninstall.exe"; Source = (Join-Path $RepoRoot "C\Util\7zipUninstall\x64\7zipUninstall.exe"); Destination = "Uninstall.exe" }
  )
}

function Get-StaticStageArtifacts {
  return @(
    @{ Name = "7-zip.chm"; Source = (Join-Path $InstallerAssetsDir "7-zip.chm"); Destination = "7-zip.chm" },
    @{ Name = "History.txt"; Source = (Join-Path $InstallerAssetsDir "History.txt"); Destination = "History.txt" },
    @{ Name = "descript.ion"; Source = (Join-Path $InstallerAssetsDir "descript.ion"); Destination = "descript.ion" },
    @{ Name = "License.txt"; Source = (Join-Path $RepoDocsDir "License.txt"); Destination = "License.txt" },
    @{ Name = "readme.txt"; Source = (Join-Path $RepoDocsDir "readme.txt"); Destination = "readme.txt" }
  )
}

function Get-InstallerStubPath {
  return (Join-Path $RepoRoot "C\Util\7zipInstall\x64\7zipInstall.exe")
}

function Resolve-SevenZipPath {
  $systemCandidates = @(
    (Join-Path $env:ProgramFiles "7-Zip\7z.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "7-Zip\7z.exe")
  )

  foreach ($candidate in $systemCandidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) {
      continue
    }

    if (Test-Path $candidate) {
      Write-Host "[7zip Installer] Usando 7-Zip do sistema: $candidate"
      return $candidate
    }
  }

  $builtSevenZip = Join-Path $RepoRoot "CPP\7zip\UI\Console\x64\7z.exe"
  $builtSevenZipDll = Join-Path $RepoRoot "CPP\7zip\UI\Console\x64\7z.dll"
  $formatDll = Join-Path $RepoRoot "CPP\7zip\Bundles\Format7zF\x64\7z.dll"

  Assert-PathExists -Path $builtSevenZip -Label "7z.exe"
  Assert-PathExists -Path $formatDll -Label "7z.dll (Format7zF)"

  if (-not (Test-Path $builtSevenZipDll)) {
    Write-Host "[7zip Installer] Copiando 7z.dll para acompanhar o 7z.exe compilado..."
    Copy-Item -Force $formatDll $builtSevenZipDll
  }

  return $builtSevenZip
}

function Build-InstallerArtifacts {
  Invoke-NMakeBuild -Label "Console x64" -WorkingDir (Join-Path $RepoRoot "CPP\7zip\UI\Console") -VcVarsPath $VcVars64
  Invoke-NMakeBuild -Label "GUI x64" -WorkingDir (Join-Path $RepoRoot "CPP\7zip\UI\GUI") -VcVarsPath $VcVars64
  Invoke-NMakeBuild -Label "File Manager x64" -WorkingDir (Join-Path $RepoRoot "CPP\7zip\Bundles\Fm") -VcVarsPath $VcVars64
  Invoke-NMakeBuild -Label "Format7zF x64" -WorkingDir (Join-Path $RepoRoot "CPP\7zip\Bundles\Format7zF") -VcVarsPath $VcVars64
  Invoke-NMakeBuild -Label "SFXWin x64" -WorkingDir (Join-Path $RepoRoot "CPP\7zip\Bundles\SFXWin") -VcVarsPath $VcVars64
  Invoke-NMakeBuild -Label "SFXCon x64" -WorkingDir (Join-Path $RepoRoot "CPP\7zip\Bundles\SFXCon") -VcVarsPath $VcVars64
  Invoke-NMakeBuild -Label "Explorer x64" -WorkingDir (Join-Path $RepoRoot "CPP\7zip\UI\Explorer") -VcVarsPath $VcVars64
  Invoke-NMakeBuild -Label "Explorer x86" -WorkingDir (Join-Path $RepoRoot "CPP\7zip\UI\Explorer") -VcVarsPath $VcVarsAmd64X86
  Invoke-NMakeBuild -Label "Uninstall x64" -WorkingDir (Join-Path $RepoRoot "C\Util\7zipUninstall") -VcVarsPath $VcVars64
  Invoke-NMakeBuild -Label "Installer Stub x64" -WorkingDir (Join-Path $RepoRoot "C\Util\7zipInstall") -VcVarsPath $VcVars64 -NMakeArgs "nmake /nologo Z7_64BIT_INSTALLER=1"

  foreach ($artifact in (Get-BuiltArtifacts)) {
    Assert-PathExists -Path $artifact.Source -Label $artifact.Name
  }

  Assert-PathExists -Path (Get-InstallerStubPath) -Label "7zipInstall.exe"
}

function Prepare-StageDirectory {
  Assert-PathExists -Path $InstallerAssetsDir -Label "Assets do instalador"
  Assert-PathExists -Path (Join-Path $RepoLangDir "en.ttt") -Label "Lang\\en.ttt"

  if (Test-Path $StageDir) {
    Remove-Item -Recurse -Force $StageDir
  }

  New-Item -ItemType Directory -Force -Path $StageDir | Out-Null

  foreach ($artifact in (Get-StaticStageArtifacts)) {
    $destination = Join-Path $StageDir $artifact.Destination
    Assert-PathExists -Path $artifact.Source -Label $artifact.Name
    Copy-Item -Force $artifact.Source $destination
  }

  $stageLangDir = Join-Path $StageDir "Lang"
  New-Item -ItemType Directory -Force -Path $stageLangDir | Out-Null
  Copy-Item -Force -Recurse (Join-Path $RepoLangDir "*") $stageLangDir
}

function Sync-StagedLangFromRepo {
  Assert-PathExists -Path (Join-Path $RepoLangDir "en.ttt") -Label "Lang\\en.ttt"

  $stageLangDir = Join-Path $StageDir "Lang"
  if (Test-Path $stageLangDir) {
    Remove-Item -Recurse -Force $stageLangDir
  }

  New-Item -ItemType Directory -Force -Path $stageLangDir | Out-Null
  Copy-Item -Force -Recurse (Join-Path $RepoLangDir "*") $stageLangDir
}

function Sync-LocalFileManagerLangFromRepo {
  Assert-PathExists -Path (Join-Path $RepoLangDir "en.ttt") -Label "Lang\\en.ttt"

  $langTargets = @(
    (Join-Path $RepoRoot "CPP\7zip\Bundles\Fm\x64\Lang"),
    (Join-Path $RepoRoot "CPP\7zip\UI\FileManager\x64\Lang")
  )

  foreach ($langTarget in $langTargets) {
    if (Test-Path $langTarget) {
      Remove-Item -Recurse -Force $langTarget
    }

    New-Item -ItemType Directory -Force -Path $langTarget | Out-Null
    Copy-Item -Force -Recurse (Join-Path $RepoLangDir "*") $langTarget
  }
}

function Ensure-LangEntry {
  param(
    [string]$LangFile,
    [string]$Id,
    [string]$Value,
    [string]$InsertBeforeId
  )

  if (-not (Test-Path $LangFile)) {
    return
  }

  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($line in (Get-Content $LangFile -Encoding UTF8)) {
    $lines.Add($line)
  }

  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -ne $Id) {
      continue
    }

    $lines.RemoveAt($i)
    if ($i -lt $lines.Count) {
      $lines.RemoveAt($i)
    }
    break
  }

  $insertIndex = -1
  if (-not [string]::IsNullOrWhiteSpace($InsertBeforeId)) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($lines[$i].Trim() -eq $InsertBeforeId) {
        $insertIndex = $i
        break
      }
    }
  }

  if ($insertIndex -lt 0) {
    [uint32]$targetId = 0
    if ([UInt32]::TryParse($Id, [ref]$targetId)) {
      for ($i = 0; $i -lt $lines.Count; $i++) {
        [uint32]$currentId = 0
        if ([UInt32]::TryParse($lines[$i].Trim(), [ref]$currentId)) {
          if ($currentId -gt $targetId) {
            $insertIndex = $i
            break
          }
        }
      }
    }
  }

  if ($insertIndex -lt 0) {
    $lines.Add($Id)
    $lines.Add($Value)
  } else {
    $lines.Insert($insertIndex, $Id)
    $lines.Insert($insertIndex + 1, $Value)
  }

  Set-Content -Path $LangFile -Value $lines -Encoding UTF8
}

function Normalize-AboutLangEntries {
  Assert-PathExists -Path $RepoLangDir -Label "Diretorio de idiomas"

  $defaultNote = "This version refers to a fork, customized to meet the needs of the developer below."
  $defaultRepo = "Repository: https://github.com/fernandoncidade/7zip/tree/simultaneous_multiple_packaging?tab=readme-ov-file"

  foreach ($langFile in (Get-ChildItem $RepoLangDir -File)) {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in (Get-Content $langFile.FullName -Encoding UTF8)) {
      $lines.Add($line)
    }

    $aboutIndex = $lines.IndexOf("2900")
    if ($aboutIndex -lt 0 -or ($aboutIndex + 2) -ge $lines.Count) {
      continue
    }

    $title = $lines[$aboutIndex + 1]
    $free = $lines[$aboutIndex + 2]
    $note = $null
    $repo = $null

    $explicitNoteIndex = $lines.IndexOf("2902")
    if ($explicitNoteIndex -ge 0 -and ($explicitNoteIndex + 1) -lt $lines.Count) {
      $note = $lines[$explicitNoteIndex + 1]
    }

    $explicitRepoIndex = $lines.IndexOf("2903")
    if ($explicitRepoIndex -ge 0 -and ($explicitRepoIndex + 1) -lt $lines.Count) {
      $repo = $lines[$explicitRepoIndex + 1]
    }

    if ([string]::IsNullOrWhiteSpace($note) -and ($aboutIndex + 3) -lt $lines.Count) {
      $candidate = $lines[$aboutIndex + 3]
      [uint32]$candidateId = 0
      if (-not [UInt32]::TryParse($candidate.Trim(), [ref]$candidateId)) {
        $note = $candidate
      }
    }

    if ([string]::IsNullOrWhiteSpace($repo) -and ($aboutIndex + 4) -lt $lines.Count) {
      $candidate = $lines[$aboutIndex + 4]
      [uint32]$candidateId = 0
      if (-not [UInt32]::TryParse($candidate.Trim(), [ref]$candidateId)) {
        $repo = $candidate
      }
    }

    if ([string]::IsNullOrWhiteSpace($note)) {
      $note = $defaultNote
    }

    if ([string]::IsNullOrWhiteSpace($repo)) {
      $repo = $defaultRepo
    }

    foreach ($id in @("2903", "2902")) {
      while ($true) {
        $index = $lines.IndexOf($id)
        if ($index -lt 0) {
          break
        }
        $lines.RemoveAt($index)
        if ($index -lt $lines.Count) {
          $lines.RemoveAt($index)
        }
      }
    }

    $aboutIndex = $lines.IndexOf("2900")
    if ($aboutIndex -lt 0) {
      continue
    }

    $nextIdIndex = $lines.Count
    for ($i = $aboutIndex + 1; $i -lt $lines.Count; $i++) {
      [uint32]$id = 0
      if ([UInt32]::TryParse($lines[$i].Trim(), [ref]$id)) {
        $nextIdIndex = $i
        break
      }
    }

    for ($i = $nextIdIndex - 1; $i -ge ($aboutIndex + 1); $i--) {
      $lines.RemoveAt($i)
    }

    $lines.Insert($aboutIndex + 1, $title)
    $lines.Insert($aboutIndex + 2, $free)
    $lines.Insert($aboutIndex + 3, $note)
    $lines.Insert($aboutIndex + 4, $repo)

    Set-Content -Path $langFile.FullName -Value $lines -Encoding UTF8
  }
}

function Sync-CustomLangEntries {
  $langDir = $RepoLangDir
  Assert-PathExists -Path $langDir -Label "Diretorio de idiomas"
  Assert-PathExists -Path (Join-Path $langDir "en.ttt") -Label "Lang\\en.ttt"

  $countTranslations = [ordered]@{
    "af.txt" = "&Aantal:"
    "an.txt" = "&Cantidat:"
    "ar.txt" = "&العدد:"
    "ast.txt" = "&Cantidá:"
    "az.txt" = "&Say:"
    "ba.txt" = "&Һаны:"
    "be.txt" = "&Колькасць:"
    "bg.txt" = "&Брой:"
    "bn.txt" = "&সংখ্যা:"
    "br.txt" = "&Niver:"
    "ca.txt" = "&Quantitat:"
    "co.txt" = "&Quantità:"
    "cs.txt" = "&Počet:"
    "cy.txt" = "&Nifer:"
    "da.txt" = "&Antal:"
    "de.txt" = "&Anzahl:"
    "el.txt" = "&Πλήθος:"
    "en.ttt" = "&Count:"
    "eo.txt" = "&Nombro:"
    "es.txt" = "&Cantidad:"
    "et.txt" = "&Arv:"
    "eu.txt" = "&Kopurua:"
    "ext.txt" = "&Cantidá:"
    "fa.txt" = "&تعداد:"
    "fi.txt" = "&Määrä:"
    "fr.txt" = "&Nombre:"
    "fur.txt" = "&Numar:"
    "fy.txt" = "&Tal:"
    "ga.txt" = "&Líon:"
    "gl.txt" = "&Cantidade:"
    "gu.txt" = "&ગણતરી:"
    "he.txt" = "&כמות:"
    "hi.txt" = "&संख्या:"
    "hr.txt" = "&Broj:"
    "hu.txt" = "&Darab:"
    "hy.txt" = "&Քանակ:"
    "id.txt" = "&Jumlah:"
    "io.txt" = "&Nombro:"
    "is.txt" = "&Fjöldi:"
    "it.txt" = "&Conteggio:"
    "ja.txt" = "&数:"
    "ka.txt" = "&რაოდენობა:"
    "kaa.txt" = "&Sani:"
    "kab.txt" = "&Amḍan:"
    "kk.txt" = "&Саны:"
    "ko.txt" = "&개수:"
    "ku-ckb.txt" = "&ژمارە:"
    "ku.txt" = "&Hejmar:"
    "ky.txt" = "&Саны:"
    "lij.txt" = "&Nùmero:"
    "lt.txt" = "&Kiekis:"
    "lv.txt" = "&Skaits:"
    "mk.txt" = "&Број:"
    "mn.txt" = "&Тоо:"
    "mng.txt" = "&Тоо:"
    "mng2.txt" = "&Тоо:"
    "mr.txt" = "&संख्या:"
    "ms.txt" = "&Jumlah:"
    "nb.txt" = "&Antall:"
    "ne.txt" = "&संख्या:"
    "nl.txt" = "&Aantal:"
    "nn.txt" = "&Tal:"
    "pa-in.txt" = "&ਗਿਣਤੀ:"
    "pl.txt" = "&Liczba:"
    "ps.txt" = "&شمېر:"
    "pt-br.txt" = "&Quantidade:"
    "pt.txt" = "&Quantidade:"
    "ro.txt" = "&Număr:"
    "ru.txt" = "&Количество:"
    "sa.txt" = "&संख्या:"
    "si.txt" = "&ගණන:"
    "sk.txt" = "&Počet:"
    "sl.txt" = "&Število:"
    "sq.txt" = "&Numër:"
    "sr-spc.txt" = "&Број:"
    "sr-spl.txt" = "&Broj:"
    "sv.txt" = "&Antal:"
    "sw.txt" = "&Idadi:"
    "ta.txt" = "&எண்ணிக்கை:"
    "tg.txt" = "&Шумора:"
    "th.txt" = "&จำนวน:"
    "tk.txt" = "&Sany:"
    "tr.txt" = "&Sayı:"
    "tt.txt" = "&Саны:"
    "ug.txt" = "&سانى:"
    "uk.txt" = "&Кількість:"
    "uz-cyrl.txt" = "&Сони:"
    "uz.txt" = "&Soni:"
    "va.txt" = "&Quantitat:"
    "vi.txt" = "&Số lượng:"
    "yo.txt" = "&Iye:"
    "zh-cn.txt" = "&数量:"
    "zh-tw.txt" = "&數量:"
  }

  foreach ($langFileName in $countTranslations.Keys) {
    Ensure-LangEntry -LangFile (Join-Path $langDir $langFileName) -Id "4021" -Value $countTranslations[$langFileName] -InsertBeforeId "4040"
  }
}

function Update-StagedArtifacts {
  foreach ($artifact in (Get-BuiltArtifacts)) {
    $destination = Join-Path $StageDir $artifact.Destination
    Write-Host "[7zip Installer] Substituindo $($artifact.Destination)..."
    Copy-Item -Force $artifact.Source $destination
  }
}

function New-PayloadArchive {
  param(
    [string]$SevenZipPath
  )

  if (Test-Path $PayloadArchive) {
    Remove-Item -Force $PayloadArchive
  }

  $items = Get-ChildItem -Force $StageDir | ForEach-Object { $_.Name }
  if ($items.Count -eq 0) {
    throw "Diretorio de stage vazio: $StageDir"
  }

  Write-Host "[7zip Installer] Reempacotando payload..."
  Push-Location $StageDir
  try {
    & $SevenZipPath a "-t7z" "-mx=9" "-m0=LZMA" "-ms=on" "-y" $PayloadArchive @items
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
  }
  finally {
    Pop-Location
  }

  Assert-PathExists -Path $PayloadArchive -Label "payload.7z"
}

function New-InstallerBinary {
  $stub = Get-InstallerStubPath
  Assert-PathExists -Path $stub -Label "7zipInstall.exe"
  Assert-PathExists -Path $PayloadArchive -Label "payload.7z"

  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
  if (Test-Path $OutputInstaller) {
    Remove-Item -Force $OutputInstaller
  }

  Write-Host "[7zip Installer] Gerando instalador final..."
  $command = 'copy /b "' + $stub + '" + "' + $PayloadArchive + '" "' + $OutputInstaller + '" >nul'
  & cmd.exe /d /c $command
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  Assert-PathExists -Path $OutputInstaller -Label "Instalador final"
}

function Validate-InstallerBinary {
  param(
    [string]$SevenZipPath
  )

  Assert-PathExists -Path $OutputInstaller -Label "Instalador final"

  Write-Host "[7zip Installer] Validando instalador..."
  & $SevenZipPath l $OutputInstaller
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  $item = Get-Item $OutputInstaller
  Write-Host "[7zip Installer] Binario gerado: $($item.FullName)"
  Write-Host "[7zip Installer] Tamanho: $($item.Length) bytes"
}

function Build-Installer {
  Build-InstallerArtifacts

  $sevenZipPath = Resolve-SevenZipPath
  Assert-PathExists -Path $sevenZipPath -Label "7z.exe"

  Sync-CustomLangEntries
  Normalize-AboutLangEntries
  Sync-LocalFileManagerLangFromRepo
  Prepare-StageDirectory
  Update-StagedArtifacts
  New-PayloadArchive -SevenZipPath $sevenZipPath
  New-InstallerBinary
  Validate-InstallerBinary -SevenZipPath $sevenZipPath
}

function Run-Installer {
  $installer = Get-OutputInstallerPath
  Assert-PathExists -Path $installer -Label "Instalador final"

  $process = Start-Process -FilePath $installer -WorkingDirectory ((Split-Path -Parent $installer)) -PassThru
  Write-Host "[7zip Installer] Executando: $installer"
  Write-Host "[7zip Installer] PID: $($process.Id)"
}

switch ($Action) {
  "build" { Build-Installer }
  "run" { Run-Installer }
  "sync-lang" {
    Sync-CustomLangEntries
    Normalize-AboutLangEntries
    Sync-LocalFileManagerLangFromRepo
    if (Test-Path $StageDir) {
      Sync-StagedLangFromRepo
    }
  }
  "build-run" {
    Build-Installer
    Run-Installer
  }
}
