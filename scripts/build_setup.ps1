$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
  $pubspec = Get-Content -Path (Join-Path $repoRoot 'pubspec.yaml') -Raw
  if ($pubspec -match '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
    $appVersion = $Matches[1]
  } else {
    $appVersion = '1.0.0'
  }

  Write-Host "Building Awake v$appVersion for Windows (Release)..."
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows --release failed with exit code $LASTEXITCODE"
  }

  $candidatePaths = @(
    (Get-Command iscc -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe'
  ) | Where-Object { $_ -and (Test-Path $_) }

  $iscc = $candidatePaths | Select-Object -First 1
  if (-not $iscc) {
    throw "Inno Setup 6 (ISCC.exe) was not found. Install it via: winget install JRSoftware.InnoSetup"
  }

  $issPath = Join-Path $repoRoot 'windows\installer\awake.iss'
  Write-Host "Compiling installer with $iscc..."
  & $iscc "/DMyAppVersion=$appVersion" $issPath
  if ($LASTEXITCODE -ne 0) {
    throw "ISCC.exe failed with exit code $LASTEXITCODE"
  }

  $setupExe = Join-Path $repoRoot "dist\Awake-$appVersion-Setup.exe"
  Get-Item $setupExe | Select-Object FullName, Length
} finally {
  Pop-Location
}
