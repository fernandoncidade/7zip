[CmdletBinding(SupportsShouldProcess = $true)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

$targets = @(
    'C\Util\7zipInstall\x64'
    'C\Util\7zipUninstall\x64'
    'CPP\7zip\Bundles\Alone\x64'
    'CPP\7zip\Bundles\Alone2\x64'
    'CPP\7zip\Bundles\Alone7z\x64'
    'CPP\7zip\Bundles\Fm\x64'
    'CPP\7zip\Bundles\Fm\_tmp'
    'CPP\7zip\Bundles\Format7z\x64'
    'CPP\7zip\Bundles\Format7zExtract\x64'
    'CPP\7zip\Bundles\Format7zExtractR\x64'
    'CPP\7zip\Bundles\Format7zF\x64'
    'CPP\7zip\Bundles\Format7zR\x64'
    'CPP\7zip\Bundles\LzmaCon\x64'
    'CPP\7zip\Bundles\SFXCon\x64'
    'CPP\7zip\Bundles\SFXSetup\x64'
    'CPP\7zip\Bundles\SFXWin\x64'
    'CPP\7zip\UI\Client7z\x64'
    'CPP\7zip\UI\Console\x64'
    'CPP\7zip\UI\Console\_o'
    'CPP\7zip\UI\Explorer\x86'
    'CPP\7zip\UI\Explorer\x64'
    'CPP\7zip\UI\Far\x64'
    'CPP\7zip\UI\FileManager\x64'
    'CPP\7zip\UI\GUI\x64'
    'CPP\7zip\UI\GUI\_tmp'
) | ForEach-Object {
    if ([System.IO.Path]::IsPathRooted($_)) {
        $_
    }
    else {
        Join-Path $repoRoot $_
    }
}

$removed = 0
$missing = 0

foreach ($target in $targets) {
    if (Test-Path -LiteralPath $target) {
        if ($PSCmdlet.ShouldProcess($target, 'Remover arquivo ou pasta regenerada')) {
            Remove-Item -LiteralPath $target -Recurse -Force
            Write-Host "Removido: $target"
            $removed++
        }
    }
    else {
        Write-Host "Nao encontrado: $target"
        $missing++
    }
}

Write-Host ""
Write-Host "Concluido. Removidos: $removed. Nao encontrados: $missing."
