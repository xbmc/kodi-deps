# Kodi Dependencies for Windows (32 and 64 Bit)

## Requirements ##

in `vsconfigs` there are configurations that can be imported in the Visual Studio Installer.
Click More->Import Configuration and pick the one matching the VS version. This should
install everything required in the VS installer, everything else still need to be installed
manually

### Common

- git
- perl
- windows driver kit (wdk)
- jdk (Use SE 8 from oracle, using AdoptOpenJDK produced a build that didn't work)
- ant
- windows sdk 10.0.17763.0
- cmake 3.16 or higher

### VS 2017

- c++ development and universal development workloads
- atl
- mfc
- build tools for x86, x64, arm, arm64

### VS 2019

- c++ development and universal development workloads
- atl
- atl spectre mitigations
- mfc
- mfc spectre mitigrations
- build tools for x86, x64, arm, arm64
- crt libraries with spectre mitigations


## Build and release

Run `DoRelease.ps1 -App -Desktop` in a powershell window. It will clean any previous builds,
build libraries that require a debug build in debug, build all libraries as
RelWithDebInfo for every platform and then package them. It takes a while to run.

If no errors occured libraries are now available in the `package` folder and ready
to be uploaded to ftp.

## How to add a new dependency
1. open CMakeLists.txt
2. add the following template and add the missing values
   - `DOWNLOAD_NAME`, `BUILD_COMMAND` is not needed in most cases and can be removed
   - If the package has dependencies add them at `DEPENDS` otherwise remove the line
     For every dependency you need to add `%3B%3B${PREFIX}/<DEPENDS-NAME>` at the end of `CMAKE_INSTALL_PREFIX`
   - The prefered way is to point to a git repo with patches. The convention is to create a branch named kodi with the patches.
    Using git repos is easier when iterating during development as cmake will fetch a new tag and regenerate the project. When using a patch, you have to manually delete the directory for cmake to
    apply the patch again.
   - If the source code needs to be patched save the patch at `patches/<NAME>.diff` otherwise remove the line
   - Additionally cmake arguments can be added after `CMAKE_INSTALL_PREFIX`

```
ExternalProject_Add(<NAME>
  DEPENDS <DEPENDS>
  GIT_REPOSITORY <URL>
  GIT_TAG <sha1>
  GIT_SHALLOW ON
  BUILD_COMMAND <BUILD-COMMAND>
  CMAKE_ARGS
    ${ADDITIONAL_ARGS}
    -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
```
```
ExternalProject_Add(<NAME>
  DOWNLOAD_NAME <DOWNLOAD_NAME>
  DEPENDS <DEPENDS>
  DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
  URL <URL>
  URL_HASH SHA256=<SHA256-HASH>
  PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
  BUILD_COMMAND <BUILD-COMMAND>
  CMAKE_ARGS
    ${ADDITIONAL_ARGS}
    -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
```


## How to bump version for a dependency
1. open CMakeLists.txt
2. update the corresponding ExternalProject_Add and `patches/<NAME>.diff`
