cmake_minimum_required(VERSION 3.2)

project(KodiDependencies)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

option(FOLDER_PER_TARGET "install dependencies in separate folders" ON)
option(FOLDER_PER_PLATFORM "separate platform folders" ON)

if(NOT PREFIX)
	set(PREFIX "${CMAKE_SOURCE_DIR}/package")
endif()

set(KODI_PATH project/BuildDependencies)

if(FOLDER_PER_PLATFORM)
	set(KODI_PATH "${KODI_PATH}/$(Platform)")
endif()

if(FOLDER_PER_TARGET)
	set(INSTALL_PREFIX "${PREFIX}/$(TargetName)/${KODI_PATH}")
else()
	set(INSTALL_PREFIX "${PREFIX}/${KODI_PATH}")
endif()

message(STATUS "  FOLDER_PER_TARGET: ${FOLDER_PER_TARGET}")
message(STATUS "FOLDER_PER_PLATFORM: ${FOLDER_PER_PLATFORM}")
message(STATUS "             PREFIX: ${PREFIX}")
message(STATUS "          KODI_PATH: ${KODI_PATH}")
message(STATUS "     INSTALL_PREFIX: ${INSTALL_PREFIX}")

include(ExternalProject)


# dependencies required by others

ExternalProject_Add(expat
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://sourceforge.net/projects/expat/files/expat/2.2.0/expat-2.2.0.tar.bz2
	URL_HASH SHA256=d9e50ff2d19b3538bd2127902a89987474e1a4db8e43a66a4d1a712ab9a504ff
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-BUILD_tests:BOOL=OFF
		-DBUILD_doc:BOOL=OFF
		-DBUILD_examples:BOOL=OFF
		-DBUILD_tools:BOOL=OFF
		-DBUILD_shared:BOOL=OFF
)

ExternalProject_Add(libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz
	URL_HASH SHA256=ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(openssl
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://www.openssl.org/source/openssl-1.0.2k.tar.gz
	URL_HASH SHA256=6b3977c61f2aedf0f96367dcfb5c6e578cf37e7b8d913b4ecb6643c3cb88d8c0
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	INSTALL_COMMAND
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(zlib
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://zlib.net/zlib-1.2.11.tar.gz
	URL_HASH SHA256=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1
	PATCH_COMMAND del zconf.h COMMAND mkdir cmake COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_EXAMPLES:BOOL=OFF
		-DBUILD_SHARED_LIBS:BOOL=OFF
		-DSKIP_INSTALL_FILES:BOOL=ON
		-DASM686:BOOL=OFF
		-DAMD64:BOOL=ON
)


# Required dependencies

ExternalProject_Add(cpluff
	DEPENDS expat
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://www.c-pluff.org/downloads/cpluff-0.1.3.tar.gz
	URL_HASH SHA256=bae2ff7c3df4cf3cd9b0f32936ebe88c61d7da7c60a33b7cef4b98f8fca9c73c
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/expat/${KODI_PATH}
)

ExternalProject_Add(crossguid
	DOWNLOAD_NAME crossguid-fef89a4.tar.gz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/graeme-hill/crossguid/archive/fef89a4.tar.gz
	URL_HASH SHA256=271f0cc8ca79f4e56398439c5d6e59dcc47b34f27b54ecda2491ef901e5bd65d
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(easyhook
	DOWNLOAD_NAME easyhook-2.7.6035.0.tar.gz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/EasyHook/EasyHook/archive/v2.7.6035.0.tar.gz
	URL_HASH SHA256=db5dafbc08ccd181dc8f2e11a7adf63b3e90b6bea974c326ce15fc4ba70d96b4
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(freetype
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://download.savannah.gnu.org/releases/freetype/freetype-2.7.1.tar.gz
	URL_HASH SHA256=162ef25aa64480b1189cdb261228e6c5c44f212aac4b4621e28cf2157efb59f5
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(libcdio
	DEPENDS libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://ftp.gnu.org/gnu/libcdio/libcdio-0.94.tar.gz
	URL_HASH SHA256=96e2c903f866ae96f9f5b9048fa32db0921464a2286f5b586c0f02699710025a
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/libiconv/${KODI_PATH}
)

ExternalProject_Add(libfribidi
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://fribidi.org/download/fribidi-0.19.7.tar.bz2
	URL_HASH SHA256=08222a6212bbc2276a2d55c3bf370109ae4a35b689acbc66571ad2a670595a8e
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(libyajl
	DOWNLOAD_NAME yajl-2.1.0.tar.gz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/lloyd/yajl/archive/2.1.0.tar.gz
	URL_HASH SHA256=3fb73364a5a30efe615046d07e6db9d09fd2b41c763c5f7d3bfb121cd5c5ac5a
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_BIN:BOOL=OFF
		-DBUILD_EXAMPLE:BOOL=OFF
		-DBUILD_TEST:BOOL=OFF
)

ExternalProject_Add(lzo2
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://www.oberhumer.com/opensource/lzo/download/lzo-2.09.tar.gz
	URL_HASH SHA256=f294a7ced313063c057c504257f437c8335c41bfeed23531ee4e6a2b87bcb34c
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(pcre
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://ftp.pcre.org/pub/pcre/pcre-8.40.tar.gz
	URL_HASH SHA256=1d75ce90ea3f81ee080cdc04e68c9c25a9fb984861a0618be7bbf676b18eda3e
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DINSTALL_DOC:BOOL=OFF
		-DINSTALL_MSVC_PDB:BOOL=ON
		-DPCRE_BUILD_PCREGREP:BOOL=OFF
		-DPCRE_BUILD_TESTS:BOOL=OFF
		-DPCRE_MATCH_LIMIT_RECURSION=1500
		-DPCRE_NEWLINE=ANYCRLF
		-DPCRE_NO_RECURSE:BOOL=ON
		-DPCRE_SUPPORT_JIT:BOOL=ON
		-DPCRE_SUPPORT_UNICODE_PROPERTIES:BOOL=ON
		-DPCRE_SUPPORT_UTF:BOOL=ON
)

ExternalProject_Add(sqlite
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://sqlite.com/2017/sqlite-amalgamation-3160200.zip
	URL_HASH SHA256=3ea98729366ec1d38d13a860aa10cfe29a355bfe089c32080987e2771514c42b
	PATCH_COMMAND mkdir cmake COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(taglib
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://taglib.org/releases/taglib-1.11.1.tar.gz
	URL_HASH SHA256=b6d1a5a610aae6ff39d93de5efd0fdc787aa9e9dc1e7026fa4c961b26563526b
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(tinyxml
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://sourceforge.net/projects/tinyxml/files/tinyxml/2.6.2/tinyxml_2_6_2.tar.gz
	URL_HASH SHA256=15bdfdcec58a7da30adc87ac2b078e4417dbe5392f3afb719f9ba6d062645593
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

add_custom_target(DependenciesRequired
	DEPENDS
		cpluff
		crossguid
		easyhook
		freetype
		libcdio
		libfribidi
		libyajl
		lzo2
		pcre
		sqlite
		taglib
		tinyxml
)


# Required, dyloaded deps

ExternalProject_Add(libass
	DEPENDS freetype libfribidi libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/libass/libass/releases/download/0.13.6/libass-0.13.6.tar.gz
	URL_HASH SHA256=62070da83b2139c1875c9db65ece37f80f955097227b7d46ade680221efdff4b
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	INSTALL_COMMAND 
	CMAKE_ARGS
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/freetype/${KODI_PATH}%3B%3B${PREFIX}/libfribidi/${KODI_PATH}%3B%3B${PREFIX}/libiconv/${KODI_PATH}
		-DBUILD_SHARED_LIBS:BOOL=ON
)
