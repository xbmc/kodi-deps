[CmdletBinding()]
Param(
  [Parameter()]
  [string[]] $Packages,
  [switch] $GenerateProjects,
  [switch] $Rel = $false,
  [switch] $Deb = $false,
  [switch] $Rebuild = $false
)

$ErrorActionPreference = "Stop"

$platforms = @( 'arm', 'win32', 'x64', 'arm64' )

if ($GenerateProjects) {
  foreach ($platform in $platforms) {
    $path = "$PsScriptRoot\Build\$platform"
    if (!(Test-Path $path)) {
      New-Item $path -ItemType Directory
    }
    cmake -G "Visual Studio 16" -A $platform -Thost=x64 -S $PsScriptRoot -B $path

    $path = "$PsScriptRoot\Build\win10-$Platform"
    if (!(Test-Path $path)) {
      New-Item $path -ItemType Directory
    }
    cmake -G "Visual Studio 16" -A $platform -Thost=x64 -DCMAKE_SYSTEM_NAME=WindowsStore -DCMAKE_SYSTEM_VERSION='10.0' -S $PsScriptRoot -B $path
  }
}

if ($null -ne $Packages) {
  $cleanFirst
  if ($Rebuild) {
    $cleanFirst = "--clean-first"
  }
  foreach ($package in $Packages) {
    foreach ($platform in $platforms) {
      $path = "$PsScriptRoot\Build\$platform"
      if ($Deb) {
        cmake --build $path --config Debug -t $package $cleanFirst
        if ($LASTEXITCODE -ne 0) { return; }
      }

      if ($Rel) {
        cmake --build $path --config RelWithDebInfo -t $package $cleanFirst
        if ($LASTEXITCODE -ne 0) { return; }
      }

      $storePath = "$PsScriptRoot\Build\win10-$Platform"
      if ($Deb) {
        cmake --build $storePath --config Debug -t $package $cleanFirst
        if ($LASTEXITCODE -ne 0) { return; }
      }

      if ($Rel) {
        cmake --build $storePath --config RelWithDebInfo -t $package $cleanFirst
        if ($LASTEXITCODE -ne 0) { return; }
      }
    }
  }
}