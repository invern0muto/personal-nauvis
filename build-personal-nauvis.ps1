param(
    [switch]$Install,
    [string]$ModsDir
)

$ErrorActionPreference = "Stop"
$modRoot = Join-Path $PSScriptRoot "mods\personal-nauvis"
$info = Get-Content (Join-Path $modRoot "info.json") -Raw | ConvertFrom-Json
$folder = "$($info.name)_$($info.version)"
$distDir = Join-Path $PSScriptRoot "dist"
$stageRoot = Join-Path $distDir "_personal_nauvis_stage"
$stageDir = Join-Path $stageRoot $folder
$zipPath = Join-Path $distDir "$folder.zip"

if (Test-Path $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force }
if (Test-Path $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

foreach ($item in Get-ChildItem -LiteralPath $modRoot -Force) {
    Copy-Item -LiteralPath $item.FullName -Destination $stageDir -Recurse
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $prefixLength = $stageRoot.Length + 1
    foreach ($item in Get-ChildItem -LiteralPath $stageRoot -Recurse -File) {
        $entryName = $item.FullName.Substring($prefixLength).Replace('\', '/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip, $item.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal)
    }
} finally {
    $zip.Dispose()
}
Remove-Item -LiteralPath $stageRoot -Recurse -Force
Write-Host "Built $zipPath"

if ($Install) {
    $targetDir = if ($ModsDir) { $ModsDir } else { Join-Path $env:APPDATA "Factorio\mods" }
    if (-not (Test-Path -LiteralPath $targetDir)) { throw "Mods directory not found: $targetDir" }
    Get-ChildItem -LiteralPath $targetDir -Filter "$($info.name)_*.zip" | Remove-Item -Force
    Copy-Item -LiteralPath $zipPath -Destination $targetDir -Force
    Write-Host "Installed to $targetDir"
}
