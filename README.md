# Kodi Dependencies for Windows (32 and 64 Bit)
## How to build already added dependencies
1. check if you have patch.exe in your PATH
2. create a build directory
3. run cmake in it
   - 64 Bit: `cmake -G "Visual Studio 14 Win64" ..`
   - 32 Bit: `cmake -G "Visual Studio 14" ..`
   - If you want to build both you need to set PREFIX for at least one as they otherwise get installed in the same directory
4. open the KodiDependencies Visual Studio Solution
5. set build mode to RelWithDebInfo
6. select the dependency, right click build
7. some dependencies need to be compiled additionally in Debug mode
8. go to package directory copy the needed dependency folder add version number and arch at the end
9. pack the folder with 7-Zip
10. upload it to mirrors and adjust the files in Kodi


## How to add a new dependency
1. open CMakeLists.txt
2. add the following template and add the missing values
   - `DOWNLOAD_NAME`, `BUILD_COMMAND` is not needed in most cases and can be removed
   - If the package has dependencies add them at `DEPENDS` otherwise remove the line
     For every dependency you need to add `%3B%3B${PREFIX}/<DEPENDS-NAME>/${KODI_PATH}` at the end of `CMAKE_INSTALL_PREFIX`
   - If the source code needs to be patched save the patch at `patches/<NAME>.diff` otherwise remove the line
   - Additionally cmake arguments can be added after `CMAKE_INSTALL_PREFIX`

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
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
```


## How to bump version for a dependency
1. open CMakeLists.txt
2. update the corresponding ExternalProject_Add and `patches/<NAME>.diff`
