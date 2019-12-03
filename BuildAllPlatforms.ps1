[CmdletBinding()]
Param(
  [Parameter()]
  [ValidateSet('bzip2', 'crossguid', 'curl', 'dnssd', 'easyhook', 'expat', 'flatc', 'freetype', 'fstrcmp', 'lcms2', 'libaacs', 'libass', 'libbdplus', 'libbluray', 'libcdi', 'libcec', 'libffi', 'libfribidi', 'libgrypt', 'libgpg-error', 'libgcrypt', 'libjpeg-turbo', 'libiconv', 'libmicrohttpd', 'libnfs', 'libplist', 'libwebp', 'libxml2', 'libxsl', 'libyajl', 'lzo2', 'mariadb-connector-c', 'openssl', 'pcre', 'python', 'shairplay', 'sqlite', 'taglib', 'tinyxml', 'winflexbison', 'xz', 'zlib')]
  [string[]] $Packages = @('bzip2', 'crossguid', 'curl', 'expat', 'flatc', 'freetype', 'fstrcmp', 'lcms2', 'libaacs', 'libass', 'libbdplus', 'libbluray', 'libcdi', 'libcec', 'libffi', 'libfribidi', 'libgrypt', 'libgpg-error', 'libiconv', 'libgcrypt', 'libjpeg-turbo', 'libmicrohttpd', 'libnfs', 'libplist', 'libwebp', 'libxml2', 'libxsl', 'libyajl', 'lzo2', 'mariadb-connector-c', 'openssl', 'pcre', 'python', 'shairplay', 'sqlite', 'taglib', 'tinyxml', 'winflexbison', 'xz', 'zlib'),
  [switch] $GenerateProjects,
  [switch] $Rel = $false,
  [switch] $Deb = $false,
  [switch] $Rebuild = $false,
  [switch] $Desktop = $false,
  [switch] $App = $false,
  [ValidateSet( 'arm', 'win32', 'x64', 'arm64' )]
  [string[]] $Platforms = @( 'arm', 'win32', 'x64', 'arm64' ),
  [ValidateSet('10.0.17763.0', '10.0.18362.0')]
  [string] $SdkVersion,
  [ValidateRange(15, 16)]
  [int] $VsVersion
)

$ErrorActionPreference = "Stop"


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

if ($null -ne $Packages) {
  $cleanFirst
  if ($Rebuild) {
    $cleanFirst = "--clean-first"
  }
  foreach ($package in $Packages) {
    foreach ($platform in $platforms) {
      if ($Desktop) {
        $path = "$PsScriptRoot\Build\$platform"
        if ($Deb) {
          cmake --build $path --config Debug -t $package $cleanFirst
          if ($LASTEXITCODE -ne 0) { return; }
        }

        if ($Rel) {
          cmake --build $path --config RelWithDebInfo -t $package $cleanFirst
          if ($LASTEXITCODE -ne 0) { return; }
        }
      }

      if ($App) {
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
}