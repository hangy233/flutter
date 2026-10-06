[CmdletBinding()]
param(
  [ValidateSet('Original', 'Fixed')]
  [string]$Mode = 'Original',
  [string]$Flutter = 'flutter'
)

$ErrorActionPreference = 'Stop'
$demoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$overridePath = Join-Path $demoRoot 'pubspec_overrides.yaml'
$utf8 = [System.Text.UTF8Encoding]::new($false)

Push-Location -LiteralPath $demoRoot
try {
  # Resolve the pinned original package first, including on repeated runs.
  [System.IO.File]::WriteAllText($overridePath, "dependency_overrides: {}`n", $utf8)
  & $Flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'Resolving the original package failed.' }

  if ($Mode -eq 'Fixed') {
    $configPath = Join-Path $demoRoot '.dart_tool/package_config.json'
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    $entry = $config.packages | Where-Object { $_.name -eq 'cupertino_ui' }
    if ($null -eq $entry) { throw 'cupertino_ui is missing from package_config.json.' }
    $configUri = [Uri]::new($configPath)
    $packageUri = [Uri]::new($configUri, [string]$entry.rootUri)
    $packageRoot = $packageUri.LocalPath
    $packageSpec = Get-Content -LiteralPath (Join-Path $packageRoot 'pubspec.yaml') -Raw
    if ($packageSpec -notmatch '(?m)^version: 1\.1\.1\s*$') {
      throw 'This patch requires cupertino_ui version 1.1.1.'
    }

    # Patch an app-local copy; the shared pub cache remains original.
    $patchedRoot = Join-Path $demoRoot '.patched/cupertino_ui'
    $patchedLib = Join-Path $patchedRoot 'lib'
    New-Item -ItemType Directory -Path $patchedLib -Force | Out-Null
    Copy-Item -Path (Join-Path $packageRoot 'lib/*') -Destination $patchedLib -Recurse -Force
    foreach ($file in @('pubspec.yaml', 'LICENSE', 'AUTHORS', 'README.md', 'CHANGELOG.md', 'analysis_options.yaml')) {
      Copy-Item -LiteralPath (Join-Path $packageRoot $file) -Destination $patchedRoot -Force
    }
    $patchPath = Join-Path $demoRoot 'patches/cupertino_ui-dynamic-colors.patch'
    & git -C $patchedRoot apply --no-index --check $patchPath
    if ($LASTEXITCODE -ne 0) { throw 'The patch does not apply to the copied package.' }
    & git -C $patchedRoot apply --no-index $patchPath
    if ($LASTEXITCODE -ne 0) { throw 'Applying the package patch failed.' }

    [System.IO.File]::WriteAllText(
      $overridePath,
      "dependency_overrides:`n  cupertino_ui:`n    path: .patched/cupertino_ui`n",
      $utf8
    )
    & $Flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Resolving the patched package failed.' }
  }
  Write-Output "Prepared $Mode cupertino_ui 1.1.1 for this demo."
} finally {
  Pop-Location
}
