[CmdletBinding()]

Param(
  [Parameter()]
  [ValidateSet(
    'brotli',
    'bzip2',
    'crossguid',
    'curl',
    'dnssd',
    'easyhook',
    'expat',
    'flatc',
    'flatbuffers',
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
    'rapidjson',
    'shairplay',
    'sqlite',
    'taglib',
    'tinyxml',
    'winflexbison',
    'xz',
    'zlib',
    'uwp_compat'
  )]
  [string[]] $Packages = @(),
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

# JAVA_HOME might be set to the JRE so let's check that and
# set it to the JDK to make things a little easier
if (!(Test-Path 'HKLM:\SOFTWARE\JavaSoft\Java Development Kit\1.8')) {
  Write-Error "No JDK found. libbluray require JDK 1.8 from Oracle"
  return
}

$jdkRegistryPath = Get-ItemPropertyValue 'HKLM:\SOFTWARE\JavaSoft\Java Development Kit\1.8' -Name JavaHome
if ($env:JAVA_HOME -ne $jdkRegistryPath) {
  $env:JAVA_HOME = $jdkRegistryPath
}

$ExcludedFromUwp = @(
  'dnssd',
  'easyhook',
  'libplist',
  'shairplay',
  'platform',
  'libcec',
  'flatc'
)

if ($GenerateProjects) {
  foreach ($platform in $platforms) {
    if ($Desktop -and ($platform -notmatch 'arm')) {
      $path = "$PsScriptRoot\Build\$platform"
      cmake -G "Visual Studio $VsVersion" -A $platform -Thost=x64 -DPATCH="C:\Program Files\Git\usr\bin\patch.exe" -S $PsScriptRoot -B $path
    }

    if ($App) {
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
  if ($Desktop -and ($platform -notmatch 'arm')) {
    $path = "$PsScriptRoot\Build\$platform"
    if ($Deb) {
      cmake --build $path --config Debug -t @desktopPackages $cleanFirst -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to build, $desktopPackages"
        return;
      }
    }

    if ($Rel) {
      cmake --build $path --config RelWithDebInfo -t @desktopPackages $cleanFirst -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to build, $desktopPackages"
        return;
      }
    }
  }

  if ($App) {
    $storePath = "$PsScriptRoot\Build\win10-$Platform"
    if ($Deb) {
      cmake --build $storePath --config Debug -t @appPackages $cleanFirst -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to build, $appPackages"
        return;
      }
    }

    if ($Rel) {
      cmake --build $storePath --config RelWithDebInfo -t @appPackages $cleanFirst -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to build, $appPackages"
        return;
      }
    }
  }
}

if ($Zip) {
  if ($desktopPackages.Count -gt 0) {
    $desktopPackages = [string[]]($desktopPackages | foreach-Object { "$_-zip"})
    $appPackages = [string[]]($appPackages | foreach-Object { "$_-zip" })
  } elseif ($desktopPackages.Count -eq 0) {
    $desktopPackages = @('zip')
    $appPackages = @('zip')
  }

  foreach ($platform in $platforms) {
    if ($Desktop -and ($platform -notmatch 'arm')) {
      $path = "$PsScriptRoot\Build\$platform"

      cmake --build $path --config RelWithDebInfo -t @desktopPackages -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to package"
        return;
      }
    }

    if ($App) {
      $storePath = "$PsScriptRoot\Build\win10-$Platform"
      cmake --build $storePath --config RelWithDebInfo -t @appPackages -- -m
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Some packages failed to package"
        return;
      }
    }
  }
}

Write-Host "All done"