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
Push-Location $stageRoot
try {
  # bsdtar writes portable POSIX separators inside ZIP archives. PowerShell's
  # Compress-Archive stores Windows backslashes, rejected by the Mod Portal.
  & tar.exe -a -cf $output "companion-dashboard_0.1.0"
  if ($LASTEXITCODE -ne 0) { throw "tar.exe failed with exit code $LASTEXITCODE" }
} finally {
  Pop-Location
}
Remove-Item -LiteralPath $stageRoot -Recurse -Force

Write-Output $output
