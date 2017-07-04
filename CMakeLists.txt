cmake_minimum_required(VERSION 3.2)

project(KodiDependencies)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

option(FOLDER_PER_TARGET "install dependencies in separate folders" ON)
option(FOLDER_PER_PLATFORM "separate platform folders" ON)

if(NOT PREFIX)
	set(PREFIX "${CMAKE_SOURCE_DIR}/package")
endif()

set(KODI_PATH project/BuildDependencies)

if(CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
	set(ADDITIONAL_ARGS "-DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}" "-DCMAKE_SYSTEM_VERSION=${CMAKE_SYSTEM_VERSION}")
endif()

if(FOLDER_PER_PLATFORM)
	if(CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
		set(KODI_PATH "${KODI_PATH}/win10-$(Platform)")
	else()
		set(KODI_PATH "${KODI_PATH}/$(Platform)")
	endif()
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
message(STATUS "    ADDITIONAL_ARGS: ${ADDITIONAL_ARGS}")
message(STATUS "     INSTALL_PREFIX: ${INSTALL_PREFIX}")

find_program(PATCH patch)
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PATCH REQUIRED_VARS PATCH)
if(NOT ${PATCH_FOUND})
  message(FATAL_ERROR "patch not found")
endif()

include(ExternalProject)


# dependencies required by others

ExternalProject_Add(bzip2
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz
	URL_HASH SHA256=a2848f34fcd5d6cf47def00461fcb528a0484d8edef8208d6d2e2909dc61d9cd
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(expat
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://sourceforge.net/projects/expat/files/expat/2.2.0/expat-2.2.0.tar.bz2
	URL_HASH SHA256=d9e50ff2d19b3538bd2127902a89987474e1a4db8e43a66a4d1a712ab9a504ff
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
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
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(openssl
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://www.openssl.org/source/openssl-1.0.2k.tar.gz
	URL_HASH SHA256=6b3977c61f2aedf0f96367dcfb5c6e578cf37e7b8d913b4ecb6643c3cb88d8c0
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	INSTALL_COMMAND
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(zlib
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://zlib.net/zlib-1.2.11.tar.gz
	URL_HASH SHA256=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1
	PATCH_COMMAND del zconf.h COMMAND mkdir cmake COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_EXAMPLES:BOOL=OFF
		-DBUILD_SHARED_LIBS:BOOL=OFF
		-DSKIP_INSTALL_FILES:BOOL=ON
		-DASM686:BOOL=OFF
		-DAMD64:BOOL=OFF
)


# Required dependencies

ExternalProject_Add(cpluff
	DEPENDS expat
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://www.c-pluff.org/downloads/cpluff-0.1.3.tar.gz
	URL_HASH SHA256=bae2ff7c3df4cf3cd9b0f32936ebe88c61d7da7c60a33b7cef4b98f8fca9c73c
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/expat/${KODI_PATH}
)

ExternalProject_Add(crossguid
	DOWNLOAD_NAME crossguid-fef89a4.tar.gz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/graeme-hill/crossguid/archive/fef89a4.tar.gz
	URL_HASH SHA256=271f0cc8ca79f4e56398439c5d6e59dcc47b34f27b54ecda2491ef901e5bd65d
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

if(NOT CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
ExternalProject_Add(easyhook
	DOWNLOAD_NAME easyhook-2.7.6035.0.tar.gz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/EasyHook/EasyHook/archive/v2.7.6035.0.tar.gz
	URL_HASH SHA256=db5dafbc08ccd181dc8f2e11a7adf63b3e90b6bea974c326ce15fc4ba70d96b4
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
endif()

ExternalProject_Add(fmt
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/fmtlib/fmt/releases/download/3.0.1/fmt-3.0.1.zip
	URL_HASH SHA256=4c9af0dc919a8ae7022b44e1a03c435e42d65c866f44667d8d920d342b098550
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DFMT_DOC:BOOL=OFF
		-DFMT_TEST:BOOL=OFF
)

ExternalProject_Add(freetype
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://download.savannah.gnu.org/releases/freetype/freetype-2.7.1.tar.gz
	URL_HASH SHA256=162ef25aa64480b1189cdb261228e6c5c44f212aac4b4621e28cf2157efb59f5
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(libcdio
	DEPENDS libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://ftp.gnu.org/gnu/libcdio/libcdio-0.94.tar.gz
	URL_HASH SHA256=96e2c903f866ae96f9f5b9048fa32db0921464a2286f5b586c0f02699710025a
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/libiconv/${KODI_PATH}
)

ExternalProject_Add(libfribidi
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://fribidi.org/download/fribidi-0.19.7.tar.bz2
	URL_HASH SHA256=08222a6212bbc2276a2d55c3bf370109ae4a35b689acbc66571ad2a670595a8e
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(libyajl
	DOWNLOAD_NAME yajl-2.1.0.tar.gz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/lloyd/yajl/archive/2.1.0.tar.gz
	URL_HASH SHA256=3fb73364a5a30efe615046d07e6db9d09fd2b41c763c5f7d3bfb121cd5c5ac5a
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_BIN:BOOL=OFF
		-DBUILD_EXAMPLE:BOOL=OFF
		-DBUILD_TEST:BOOL=OFF
)

ExternalProject_Add(lzo2
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://www.oberhumer.com/opensource/lzo/download/lzo-2.09.tar.gz
	URL_HASH SHA256=f294a7ced313063c057c504257f437c8335c41bfeed23531ee4e6a2b87bcb34c
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(pcre
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://ftp.pcre.org/pub/pcre/pcre-8.40.tar.gz
	URL_HASH SHA256=1d75ce90ea3f81ee080cdc04e68c9c25a9fb984861a0618be7bbf676b18eda3e
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
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
	URL http://sqlite.com/2017/sqlite-amalgamation-3170000.zip
	URL_HASH SHA256=ad3d5152f7dd09117654736b416e656c46de83b251e71a14b9a2de3aab29cfb2
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_SHARED_LIBS:BOOL=ON
)

ExternalProject_Add(taglib
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://taglib.org/releases/taglib-1.11.1.tar.gz
	URL_HASH SHA256=b6d1a5a610aae6ff39d93de5efd0fdc787aa9e9dc1e7026fa4c961b26563526b
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(tinyxml
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://sourceforge.net/projects/tinyxml/files/tinyxml/2.6.2/tinyxml_2_6_2.tar.gz
	URL_HASH SHA256=15bdfdcec58a7da30adc87ac2b078e4417dbe5392f3afb719f9ba6d062645593
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

add_custom_target(DependenciesRequired
	DEPENDS
		cpluff
		crossguid
		easyhook
		fmt
		freetype
		libcdio
		libfribidi
		lzo2
		pcre
		rapidjson
		sqlite
		taglib
		tinyxml
)

add_custom_target(DependenciesRequiredDebug
	DEPENDS
		crossguid
		freetype
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
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	INSTALL_COMMAND 
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/freetype/${KODI_PATH}%3B%3B${PREFIX}/libfribidi/${KODI_PATH}%3B%3B${PREFIX}/libiconv/${KODI_PATH}
		-DBUILD_SHARED_LIBS:BOOL=ON
)

ExternalProject_Add(curl
	DEPENDS openssl zlib
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://curl.haxx.se/download/curl-7.52.1.tar.gz
	URL_HASH SHA256=a8984e8b20880b621f61a62d95ff3c0763a3152093a9f9ce4287cfd614add6ae
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/openssl/${KODI_PATH}%3B%3B${PREFIX}/zlib/${KODI_PATH}
		-DBUILD_CURL_EXE:BOOL=OFF
		-DBUILD_CURL_TESTS:BOOL=OFF
		-DBUILD_TESTING:BOOL=OFF
		-DCMAKE_USE_LIBSSH2:BOOL=OFF
		-DCMAKE_USE_OPENSSL:BOOL=ON
		-DENABLE_MANUAL:BOOL=OFF
)

add_custom_target(DependenciesDllRequired
	DEPENDS
		curl
		libass
)


ExternalProject_Add(dnssd
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-765.50.9.tar.gz
	URL_HASH SHA256=de61dd0034357aa50c60806726fb1f70fa8e953ff9cb62eccfb73efad10dba0a
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_SHARED_LIBS:BOOL=ON
)

ExternalProject_Add(lcms2
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://sourceforge.net/projects/lcms/files/lcms/2.8/lcms2-2.8.tar.gz
	URL_HASH SHA256=66d02b229d2ea9474e62c2b6cd6720fde946155cd1d0d2bffdab829790a0fb22
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff COMMAND
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_SHARED_LIBS:BOOL=ON
)

ExternalProject_Add(platform
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/Pulse-Eight/platform/archive/platform-2.1.0.tar.gz
	URL_HASH SHA256=ae730b5fe34c50df57db44e6925f462061e1a5b6619a20041a7aedfdda8243ef
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(libcec
	DEPENDS platform
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/Pulse-Eight/libcec/archive/libcec-4.0.2.tar.gz
	URL_HASH SHA256=b8b8dd31f3ebdd5472f03ab7d401600ea0d959b1288b9ca24bf457ef60e2ba27
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/platform/${KODI_PATH}
)

ExternalProject_Add(libgpg-error
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.27.tar.bz2
	URL_HASH SHA256=4f93aac6fecb7da2b92871bb9ee33032be6a87b174f54abf8ddf0911a22d29d2
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(libgcrypt
	DEPENDS libgpg-error
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.7.6.tar.bz2
	URL_HASH SHA256=626aafee84af9d2ce253d2c143dc1c0902dda045780cc241f39970fc60be05bc
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/libgpg-error/${KODI_PATH}
)

ExternalProject_Add(winflexbison
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://sourceforge.net/projects/winflexbison/files/win_flex_bison-2.5.9.zip
	URL_HASH SHA256=aeb05493db39c03579412a54872334dcc54a342d856a755998074008eee4ba25
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(libaacs
	DOWNLOAD_NAME libaacs-295df3f.tar.gz
	DEPENDS libgcrypt libgpg-error winflexbison
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL ftp://ftp.videolan.org/pub/videolan/libaacs/0.9.0/libaacs-0.9.0.tar.bz2
	URL_HASH SHA512=b9c658db22a0966486070d3b762509a7c0120469ab29d1e57c1b624cad309701de8b92455ec649db4d731be4a5c29c38fb4f99bb7617dbb4254270284a1903f6
	PATCH_COMMAND ${CMAKE_SOURCE_DIR}/patch.exe -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/libgcrypt/${KODI_PATH}%3B%3B${PREFIX}/libgpg-error/${KODI_PATH}%3B%3B${PREFIX}/winflexbison/${KODI_PATH}
)

ExternalProject_Add(libbdplus
	DOWNLOAD_NAME libbdplus-45c76dd.tar.gz
	DEPENDS libgcrypt libgpg-error
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/ace20022/libbdplus/archive/45c76dd.tar.gz
	URL_HASH SHA256=843081a7fb05567f5d0ca8bbe69996f3cf18bf94e76871519aa8f2e598210f7f
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/libgcrypt/${KODI_PATH}%3B%3B${PREFIX}/libgpg-error/${KODI_PATH}
)

ExternalProject_Add(libmicrohttpd
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.55.tar.gz
	URL_HASH SHA256=0c1cab8dc9f2588bd3076a28f77a7f8de9560cbf2d80e53f9a8696ada80ed0f8
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(libnfs
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/sahlberg/libnfs/archive/libnfs-1.11.0.tar.gz
	URL_HASH SHA256=fc2e45df14d8714ccd07dc2bbe919e45a2e36318bae7f045cbbb883a7854640f
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_SHARED_LIBS:BOOL=ON
)

ExternalProject_Add(libxml2
	DEPENDS libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL ftp://xmlsoft.org/libxml2/libxml2-2.9.4.tar.gz
	URL_HASH SHA256=ffb911191e509b966deb55de705387f14156e1a56b21824357cdf0053233633c
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff COMMAND
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/libiconv/${KODI_PATH}
		-DBUILD_SHARED_LIBS:BOOL=ON
)

ExternalProject_Add(libxslt
	DEPENDS libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL ftp://xmlsoft.org/libxml2/libxslt-1.1.29.tar.gz
	URL_HASH SHA256=b5976e3857837e7617b29f2249ebb5eeac34e249208d31f1fbf7a6ba7a4090ce
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff COMMAND
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/libiconv/${KODI_PATH}%3B%3B${PREFIX}/libxml2/${KODI_PATH}
		-DBUILD_SHARED_LIBS:BOOL=ON
)

ExternalProject_Add(libplist
	DEPENDS libiconv libxml2
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://www.libimobiledevice.org/downloads/libplist-1.12.tar.bz2
	URL_HASH SHA256=0effdedcb3de128c4930d8c03a3854c74c426c16728b8ab5f0a5b6bdc0b644be
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/libiconv/${KODI_PATH}%3B%3B${PREFIX}/libxml2/${KODI_PATH}
		-DBUILD_SHARED_LIBS:BOOL=ON
)

ExternalProject_Add(mysql-connector-c
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://dev.mysql.com/get/Downloads/Connector-C/mysql-connector-c-6.1.9-src.tar.gz
	URL_HASH SHA256=4e808704443365ad5b649673d03eca8fbebc0a4da9f1f96616c6bd1b1901ab2b
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/openssl/${KODI_PATH}
		-DBUILD_SHARED_LIBS:BOOL=ON
		-DINSTALL_DOC:BOOL=OFF
		-DWITH_SSL:STRING=yes
)

ExternalProject_Add(python
	DEPENDS bzip2 openssl sqlite zlib
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://www.python.org/ftp/python/2.7.13/Python-2.7.13.tgz
	URL_HASH SHA256=a4f05a0720ce0fd92626f0278b6b433eee9a6173ddf2bced7957dfb599a5ece1
	PATCH_COMMAND
		COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/python-cmake-buildsystem-b348a50.diff
		COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/bzip2/${KODI_PATH}%3B%3B${PREFIX}/openssl/${KODI_PATH}%3B%3B${PREFIX}/sqlite/${KODI_PATH}%3B%3B${PREFIX}/zlib/${KODI_PATH}
		-DCMAKE_CONFIGURATION_TYPES:STRING=RelWithDebInfo
		-DBUILD_LIBPYTHON_SHARED:BOOL=ON
		-DBUILD_TESTING:BOOL=OFF
		-DBUILD_WININST:BOOL=OFF
		-DDOWNLOAD_SOURCES:BOOL=OFF
		-DINSTALL_MANUAL:BOOL=OFF
		-DINSTALL_TEST:BOOL=OFF
)

ExternalProject_Add(shairplay
	DOWNLOAD_NAME shairplay-ce80e00.tar.gz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/juhovh/shairplay/archive/ce80e00.tar.gz
	URL_HASH SHA256=49ac0e0470ec6367f720c7b79a09165138f57b60f5949a2d9c38be5823d13294
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_SHARED_LIBS:BOOL=ON
)

ExternalProject_Add(libbluray
	DEPENDS freetype libiconv libxml2
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL ftp://ftp.videolan.org/pub/videolan/libbluray/1.0.1/libbluray-1.0.1.tar.bz2
	URL_HASH SHA512=798d38cc95af87599af5838e5c288f2536a73b33191db8ff3774cf7eb5b835006bea83693f016d47dff551001b98527d8b1f14051f673fb3b28073b820e325d7
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}/${KODI_PATH}%3B%3B${PREFIX}/freetype/${KODI_PATH}%3B%3B${PREFIX}/libiconv/${KODI_PATH}%3B%3B${PREFIX}/libxml2/${KODI_PATH}
)
