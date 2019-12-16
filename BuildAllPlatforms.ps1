[CmdletBinding()]

Param(
  [Parameter()]
  [ValidateSet(
    'bzip2',
    'crossguid',
    'curl',
    'dnssd',
    'easyhook',
    'expat',
    'flatc',
    'fmt',
    'freetype',
    'fstrcmp',
    'lcms2',
    'libaacs',
    'libass',
    'libbdplus',
    'libbluray',
    'libcdio',
    'libcec',
    'libffi',
    'libfribidi',
    'libgpg-error',
    'libgcrypt',
    'libjpeg-turbo',
    'libiconv',
    'libmicrohttpd',
    'libnfs',
    'libplist',
    'libudfread',
    'libwebp',
    'libxml2',
    'libxslt',
    'lzo2',
    'mariadb-connector-c',
    'openssl',
    'pcre',
    'platform',
    'python',
    'pillow',
    'pycryptodome',
    'shairplay',
    'sqlite',
    'taglib',
    'tinyxml',
    'winflexbison',
    'xz',
    'zlib',
    'uwp_compat'
  )]
  [string[]] $Packages = @('$all'),
  [switch] $GenerateProjects,
  [switch] $Rel = $false,
  [switch] $Deb = $false,
  [switch] $Rebuild = $false,
  [switch] $Desktop = $false,
  [switch] $App = $false,
  [ValidateSet( 'arm', 'win32', 'x64', 'arm64' )]
  [string[]] $Platforms = @( 'arm', 'win32', 'x64', 'arm64' ),
  [ValidateSet('10.0.17763.0', '10.0.18362.0')]
  [string] $SdkVersion = '10.0.17763.0',
  [ValidateSet(15, 16)]
  [int] $VsVersion = 16,
  [switch] $Zip = $false
)

$ErrorActionPreference = "Stop"


$ExcludedFromUwp = @(
  'dnssd',
  'easyhook',
  'libplist',
  'shairplay',
  'platform',
  'libcec'
)

if ($GenerateProjects) {
  foreach ($platform in $platforms) {
    if ($Desktop) {
      $path = "$PsScriptRoot\Build\$platform"
      if (!(Test-Path $path)) {
        New-Item $path -ItemType Directory
      }
      cmake -G "Visual Studio $VsVersion" -A $platform -Thost=x64 -DPATCH="C:\Program Files\Git\usr\bin\patch.exe" -S $PsScriptRoot -B $path
    }

    if ($App) {
      $path = "$PsScriptRoot\Build\win10-$Platform"
      if (!(Test-Path $path)) {
        New-Item $path -ItemType Directory
      }
      cmake -G "Visual Studio $VsVersion" -A $platform -Thost=x64 -DCMAKE_SYSTEM_NAME=WindowsStore -DCMAKE_SYSTEM_VERSION="$SdkVersion" -DPATCH="C:\Program Files\Git\usr\bin\patch.exe" -S $PsScriptRoot -B $path
    }
  }
}

$cleanFirst
if ($Rebuild) {
  $cleanFirst = "--clean-first"
}
foreach ($package in $Packages) {
  if ('$all' -eq $package) {
    $package = ''
  }

  foreach ($platform in $platforms) {
    if ($Desktop) {
      $path = "$PsScriptRoot\Build\$platform"
      if ($Deb) {
        cmake --build $path --config Debug -t $package $cleanFirst -- -m
        if ($LASTEXITCODE -ne 0) {
          Write-Error "Some packages failed to build, $package"
           return;
        }
      }

      if ($Rel) {
        cmake --build $path --config RelWithDebInfo -t $package $cleanFirst -- -m
        if ($LASTEXITCODE -ne 0) {
          Write-Error "Some packages failed to build, $package"
           return;
        }
      }
    }

    if ($App) {
      if ($package -in $ExcludedFromUwp) {
        Write-Warning "Ignoring $package as it isn't used for uwp"
        continue
      }

      $storePath = "$PsScriptRoot\Build\win10-$Platform"
      if ($Deb) {
        cmake --build $storePath --config Debug -t $package $cleanFirst -- -m
        if ($LASTEXITCODE -ne 0) {
          Write-Error "Some packages failed to build, $package"
           return;
        }
      }

      if ($Rel) {
        cmake --build $storePath --config RelWithDebInfo -t $package $cleanFirst -- -m
        if ($LASTEXITCODE -ne 0) {
          Write-Error "Some packages failed to build, $package"
           return;
        }
      }
    }
  }
}

if ($Zip) {
  if (($Packages.Count -eq 1) -and ($Packages[0] -eq '$all')) {
    $Packages = @(
      'bzip2',
      'crossguid',
      'curl',
      'dnssd',
      'easyhook',
      'expat',
      'flatc',
      'fmt',
      'freetype',
      'fstrcmp',
      'lcms2',
      'libaacs',
      'libass',
      'libbdplus',
      'libbluray',
      'libcdio',
      'libcec',
      'libffi',
      'libfribidi',
      'libgpg-error',
      'libgcrypt',
      'libjpeg-turbo',
      'libiconv',
      'libmicrohttpd',
      'libnfs',
      'libplist',
      'libudfread',
      'libwebp',
      'libxml2',
      'libxslt',
      'lzo2',
      'mariadb-connector-c',
      'openssl',
      'pcre',
      'platform',
      'python',
      'pillow',
      'pycryptodome',
      'shairplay',
      'sqlite',
      'taglib',
      'tinyxml',
      'winflexbison',
      'xz',
      'zlib',
      'uwp_compat'
    )
  }
  foreach ($package in $Packages) {
    foreach ($platform in $platforms) {
      if ($Desktop) {
        $path = "$PsScriptRoot\Build\$platform"

        cmake --build $path --config RelWithDebInfo -t "$package-zip" -- -m
        if ($LASTEXITCODE -ne 0) {
          Write-Error "Some packages failed to build, $package"
           return;
        }
      }

      if ($App) {
        if ($package -in $ExcludedFromUwp) {
          Write-Warning "Ignoring $package as it isn't used for uwp"
          continue
        }

        $storePath = "$PsScriptRoot\Build\win10-$Platform"
        cmake --build $storePath --config RelWithDebInfo -t "$package-zip" -- -m
        if ($LASTEXITCODE -ne 0) {
          Write-Error "Some packages failed to build, $package"
          return;
        }
      }
    }
  }
}

Write-Host "All done"