[CmdletBinding()]
Param(
  [switch] $Desktop,
  [switch] $App,
  [switch] $NoClean,
  [ValidateSet( 'arm', 'win32', 'x64', 'arm64' )]
  [string[]] $Platforms = @( 'arm', 'win32', 'x64', 'arm64' ),
  [ValidateSet('10.0.17763.0', '10.0.18362.0')]
  [string] $SdkVersion = '10.0.18362.0',
  [ValidateSet(15, 16)]
  [int] $VsVersion = 16
)
$ErrorActionPreference = 'Stop'

$Generate = -not $NoClean

if ($false -eq $NoClean) {
  $buildPath = Join-Path $PSScriptRoot -ChildPath 'Build'
  $packagePath = Join-Path $PSScriptRoot -ChildPath 'package'
  if (Test-Path $buildPath) {
    Remove-Item -Recurse -Force $buildPath
  }
  if (Test-Path $packagePath) {
    Remove-Item -Recurse -Force $packagePath
  }
}

.\BuildAllPlatforms.ps1 -Platforms $Platforms -Desktop:$Desktop -App:$App -Deb -Packages 'DependenciesRequiredDebug' -GenerateProjects:$Generate
.\BuildAllPlatforms.ps1 -Platforms $Platforms -Desktop:$Desktop -App:$App -Rel -Zip -Packages 'DependenciesRequired'
