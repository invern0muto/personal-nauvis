$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $root "mods\companion-dashboard"
$stageRoot = Join-Path $root "dist\.companion-dashboard-stage"
$stage = Join-Path $stageRoot "companion-dashboard_0.1.0"
$output = Join-Path $root "dist\companion-dashboard_0.1.0.zip"

if (Test-Path -LiteralPath $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force }
New-Item -ItemType Directory -Path $stageRoot | Out-Null
Copy-Item -LiteralPath $source -Destination $stage -Recurse
if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output -Force }
Compress-Archive -LiteralPath $stage -DestinationPath $output -CompressionLevel Optimal
Remove-Item -LiteralPath $stageRoot -Recurse -Force

Write-Output $output
