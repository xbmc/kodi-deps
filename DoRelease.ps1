[CmdletBinding()]
Param(
  [switch] $Desktop,
  [switch] $App,
  [switch] $NoClean,
  [ValidateSet( 'arm', 'win32', 'x64', 'arm64' )]
  [string[]] $Platforms = @( 'arm', 'win32', 'x64', 'arm64'),
  [ValidateSet('10.0.17763.0', '10.0.18362.0')]
  [string] $SdkVersion = '10.0.18362.0',
  [ValidateSet(15, 16)]
  [int] $VsVersion = 16,
  [ValidateSet(
    'brotli',
    'bzip2',
    'crossguid',
    'curl',
    'dav1d',
    'detours',
    'dnssd',
    'expat',
    'flatc',
    'flatbuffers',
    'fmt',
    'freetype',
    'fstrcmp',
    'giflib',
    'GoogleTest',
    'harfbuzz',
    'lcms2',
    'libaacs',
    'libass',
    'libbdplus',
    'libbluray',
    'libcdio',
    'libcec',
    'libdvdcss',
    'libdvdnav',
    'libdvdread',
    'libffi',
    'libfribidi',
    'libgpg-error',
    'libgcrypt',
    'libjpeg-turbo',
    'libiconv',
    'libmicrohttpd',
    'libnfs',
    'libplist',
    'libpng',
    'libudfread',
    'libwebp',
    'libxml2',
    'libxslt',
    'lzo2',
    'mariadb-connector-c',
    'miniwdk',
    'Neptune',
    'nghttp2',
    'openssl',
    'pcre',
    'platform',
    'python',
    'pillow',
    'pycryptodome',
    'rapidjson',
    'shairplay',
    'spdlog',
    'sqlite',
    'swig',
    'taglib',
    'tinyxml',
    'winflexbison',
    'xz',
    'zlib',
    'uwp_compat'
  )]
  [string[]] $Packages
)
$ErrorActionPreference = 'Stop'

if ($false -eq $NoClean) {
  $buildPath = Join-Path $PSScriptRoot -ChildPath 'Build'
  $packagePath = Join-Path $PSScriptRoot -ChildPath 'package'
  if (Test-Path $buildPath) {
    Remove-Item -Recurse -Force $buildPath
  }
  if (Test-Path $packagePath) {
    Remove-Item -Recurse -Force $packagePath
  }
  .\BuildAllPlatforms.ps1 -Platforms $Platforms -GenerateProjects -Desktop:$Desktop -App:$App -VsVersion $VsVersion -SdkVersion $SdkVersion
}

$shouldBuildAsDebug = 'taglib', 'tinyxml', 'fmt', 'pcre', 'crossguid', 'lzo2', 'zlib', 'detours', 'libudfread', 'GoogleTest', 'harfbuzz'
if (-not $Packages) {
  $Packages = $shouldBuildAsDebug
}

$debugPackages = $Packages | Where-Object { $_ -In $shouldBuildAsDebug }
if ($debugPackages) {
  .\BuildAllPlatforms.ps1 -Platforms $Platforms -Desktop:$Desktop -App:$App -Deb -Packages $debugPackages
}
.\BuildAllPlatforms.ps1 -Platforms $Platforms -Desktop:$Desktop -App:$App -Rel -Zip