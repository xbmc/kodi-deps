[CmdletBinding()]

Param(
  [Parameter()]
  [ValidateSet(
    'bzip2',
    'detours',
    'dnssd',
    'expat',
    'freetype',
    'fstrcmp',
    'giflib',
    'harfbuzz',
    'libaacs',
    'libbdplus',
    'libcdio',
    'libdovi',
    'libffi',
    'libfribidi',
    'libgpg-error',
    'libgcrypt',
    'libjpeg-turbo',
    'libiconv',
    'libplist',
    'libpng',
    'libwebp',
    'libxml2',
    'miniwdk',
    'openssl',
    'python',
    'pillow',
    'pycryptodome',
    'shairplay',
    'sqlite',
    'tinyxml',
    'winflexbison',
    'xz',
    'zlib',
    'zstd',
    'DependenciesRequired',
    'DependenciesRequiredDebug'
  )]
  [string[]] $Packages = @('DependenciesRequired'),
  [switch] $GenerateProjects,
  [switch] $Rel = $false,
  [switch] $Deb = $false,
  [switch] $Rebuild = $false,
  [switch] $Desktop = $false,
  [switch] $App = $false,
  [ValidateSet( 'win32', 'x64', 'arm64' )]
  [string[]] $Platforms = @( 'win32', 'x64', 'arm64' ),
  [ValidateSet('10.0.18362.0', '10.0.22621.0')]
  [string] $SdkVersion = '10.0.22621.0',
  [ValidateSet(16, 17)]
  [int] $VsVersion = 17,
  [switch] $Zip = $false
)

$ErrorActionPreference = "Stop"

$ExcludedFromUwp = @(
  'detours',
  'dnssd',
  'libplist',
  'shairplay'
)

if ($GenerateProjects) {
  foreach ($platform in $platforms) {
    if ($Desktop -and ($platform -ne 'arm')) {
      $path = "$PsScriptRoot\Build\$platform"
      cmake -G "Visual Studio $VsVersion" -A $platform -Thost=x64 -DPATCH="C:\Program Files\Git\usr\bin\patch.exe" -S $PsScriptRoot -B $path
    }

    if ($App -and ($platform -ne 'arm64') -and ($platform -ne 'win32')) {
      $path = "$PsScriptRoot\Build\win10-$Platform"
      cmake -G "Visual Studio $VsVersion" -A $platform -Thost=x64 -DCMAKE_SYSTEM_NAME=WindowsStore -DCMAKE_SYSTEM_VERSION="$SdkVersion" -DPATCH="C:\Program Files\Git\usr\bin\patch.exe" -S $PsScriptRoot -B $path
    }
  }
}

$cleanFirst
if ($Rebuild) {
  $cleanFirst = "--clean-first"
}

$desktopPackages = $Packages
$appPackages = [string[]]($Packages | Where-Object { $_ -notin $ExcludedFromUwp })

foreach ($platform in $platforms) {
  if ($Desktop -and ($platform -ne 'arm')) {
    $path = "$PsScriptRoot\Build\$platform"
    if ($Deb) {
      cmake --build $path --config Debug -t @desktopPackages $cleanFirst --parallel -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to build, $desktopPackages"
        return;
      }
    }

    if ($Rel) {
      cmake --build $path --config RelWithDebInfo -t @desktopPackages $cleanFirst --parallel -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to build, $desktopPackages"
        return;
      }
    }
  }

  if ($App -and ($platform -ne 'arm64') -and ($platform -ne 'win32')) {
    $storePath = "$PsScriptRoot\Build\win10-$Platform"
    if ($Deb) {
      cmake --build $storePath --config Debug -t @appPackages $cleanFirst --parallel -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to build, $appPackages"
        return;
      }
    }

    if ($Rel) {
      cmake --build $storePath --config RelWithDebInfo -t @appPackages $cleanFirst --parallel -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to build, $appPackages"
        return;
      }
    }
  }
}

if ($Zip) {
  if ($desktopPackages.Count -gt 0) {
    $desktopPackages = [string[]]($desktopPackages | foreach-Object { "$_-zip" })
    $appPackages = [string[]]($appPackages | foreach-Object { "$_-zip" })
  }
  elseif ($desktopPackages.Count -eq 0) {
    $desktopPackages = @('zip')
    $appPackages = @('zip')
  }

  foreach ($platform in $platforms) {
    if ($Desktop -and ($platform -ne 'arm')) {
      $path = "$PsScriptRoot\Build\$platform"

      cmake --build $path --config RelWithDebInfo -t @desktopPackages --parallel -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to package"
        return;
      }
    }

    if ($App -and ($platform -ne 'arm64') -and ($platform -ne 'win32')) {
      $storePath = "$PsScriptRoot\Build\win10-$Platform"
      cmake --build $storePath --config RelWithDebInfo -t @appPackages --parallel -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to package"
        return;
      }
    }
  }
}

Write-Host "All done"