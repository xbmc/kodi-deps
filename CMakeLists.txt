cmake_minimum_required(VERSION 3.4)

project(KodiDependencies LANGUAGES C)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

option(FOLDER_PER_TARGET "install dependencies in separate folders" ON)

include(CheckSymbolExists)

check_symbol_exists(_X86_ "Windows.h" _X86_)
check_symbol_exists(_AMD64_ "Windows.h" _AMD64_)
check_symbol_exists(_ARM_ "Windows.h" _ARM_)
check_symbol_exists(_ARM64_ "Windows.h" _ARM64_)

if(_X86_)
   set(ARCH win32)
elseif(_AMD64_)
   set(ARCH x64)
elseif(_ARM_)
   set(ARCH arm)
elseif(_ARM64_)
   set(ARCH arm64)
else()
   set(ARCH unknown)
endif()

unset(_X86_)
unset(_AMD64_)
unset(_ARM_)
unset(_ARM64_)

if(CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
	set(ADDITIONAL_ARGS "-DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}" "-DCMAKE_SYSTEM_VERSION=${CMAKE_SYSTEM_VERSION}")
	set(ARCH "win10-${ARCH}")
endif()

if(NOT PREFIX)
	set(PREFIX "${CMAKE_SOURCE_DIR}/package/${ARCH}")
endif()

if(FOLDER_PER_TARGET)
	set(INSTALL_PREFIX "${PREFIX}/$(TargetName)")
else()
	set(INSTALL_PREFIX "${PREFIX}")
endif()

message(STATUS "  FOLDER_PER_TARGET: ${FOLDER_PER_TARGET}")
message(STATUS "             PREFIX: ${PREFIX}")
message(STATUS "    ADDITIONAL_ARGS: ${ADDITIONAL_ARGS}")
message(STATUS "     INSTALL_PREFIX: ${INSTALL_PREFIX}")

find_program(PATCH patch)
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PATCH REQUIRED_VARS PATCH)
if(NOT ${PATCH_FOUND})
  message(FATAL_ERROR "patch not found")
endif()

include(ExternalProject)

function(add_dependency_project_package name version)
	# it's possible to pack dependency only if it was installed in separate folder
	if(FOLDER_PER_TARGET)
		set(dep_name "${name}-${version}")
		if(NOT ANY IN_LIST ARGN)
			if(CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
				set(dep_name "${dep_name}-win10")
			endif()
			set(dep_name "${dep_name}-$(Platform)-$(PlatformToolset)")
		endif()
		file(TO_NATIVE_PATH "${PREFIX}/${dep_name}" COPY_DESTINATION)

		ExternalProject_Add_StepTargets(${name} zip)
		ExternalProject_Add_Step(${name} zip
			COMMENT "Packaging '${name}'"
			COMMAND ${CMAKE_COMMAND} -E copy_directory "${name}" "${COPY_DESTINATION}"
			COMMAND ${CMAKE_COMMAND} -E tar "cf" "${PREFIX}/../${dep_name}.7z" --format=7zip -- "${COPY_DESTINATION}"
			COMMAND ${CMAKE_COMMAND} -E remove_directory "${COPY_DESTINATION}"
			WORKING_DIRECTORY ${PREFIX}
			ALWAYS FALSE
			EXCLUDE_FROM_MAIN TRUE
		)
		ExternalProject_Add_StepDependencies(${name} zip ${name})
	endif()
endfunction()


# Executables for build

ExternalProject_Add(flatc
	DOWNLOAD_NAME flatbuffers-1.9.0.tar.gz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/google/flatbuffers/archive/v1.9.0.tar.gz
	URL_HASH SHA256=5ca5491e4260cacae30f1a5786d109230db3f3a6e5a0eb45d0d0608293d247e3
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DFLATBUFFERS_BUILD_FLATHASH:BOOL=OFF
		-DFLATBUFFERS_BUILD_FLATLIB:BOOL=OFF
		-DFLATBUFFERS_BUILD_TESTS:BOOL=OFF
)
add_dependency_project_package(flatc 1.9.0)


# dependencies required by others

ExternalProject_Add(bzip2
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://mirrors.kodi.tv/build-deps/sources/bzip2-1.0.6.tar.gz
	URL_HASH SHA256=a2848f34fcd5d6cf47def00461fcb528a0484d8edef8208d6d2e2909dc61d9cd
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(bzip2 1.0.6)

ExternalProject_Add(expat
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/libexpat/libexpat/archive/R_2_2_9.tar.gz
	URL_HASH SHA256=c341ac8c79e021cc3392a6d76e138e62d1dd287592cb455148540331756a2208
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DEXPAT_BUILD_TESTS:BOOL=OFF
		-DEXPAT_BUILD_DOCS:BOOL=OFF
		-DEXPAT_BUILD_EXAMPLES:BOOL=OFF
		-DEXPAT_BUILD_TOOLS:BOOL=OFF
		-DEXPAT_SHARED_LIBS:BOOL=OFF
  SOURCE_SUBDIR expat
)
add_dependency_project_package(expat 2.2.9)

ExternalProject_Add(libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz
	URL_HASH SHA256=e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libiconv 1.16)

ExternalProject_Add(openssl
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://www.openssl.org/source/openssl-1.1.1.tar.gz
	URL_HASH SHA256=2836875a0f89c03d0fdf483941512613a50cfb421d6fd94b9f41d7279d586a3d
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	INSTALL_COMMAND
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(openssl 1.1.1)

ExternalProject_Add(zlib
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://zlib.net/zlib-1.2.11.tar.gz
	URL_HASH SHA256=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_EXAMPLES:BOOL=OFF
		-DBUILD_SHARED_LIBS:BOOL=OFF
		-DSKIP_INSTALL_FILES:BOOL=ON
		-DASM686:BOOL=OFF
		-DAMD64:BOOL=OFF
)
add_dependency_project_package(zlib 1.2.11)

ExternalProject_Add(xz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://netix.dl.sourceforge.net/project/lzmautils/xz-5.2.4.tar.gz
	URL_HASH SHA256=b512f3b726d3b37b6dc4c8570e137b9311e7552e8ccbab4d39d47ce5f4177145
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(xz 5.2.4)


# Required dependencies

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
add_dependency_project_package(crossguid fef89a4)

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
add_dependency_project_package(easyhook 2.7.6035.0)
endif()

ExternalProject_Add(flatbuffers
	DOWNLOAD_NAME flatbuffers-1.9.0.tar.gz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/google/flatbuffers/archive/v1.9.0.tar.gz
	URL_HASH SHA256=5ca5491e4260cacae30f1a5786d109230db3f3a6e5a0eb45d0d0608293d247e3
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DFLATBUFFERS_BUILD_FLATC:BOOL=OFF
		-DFLATBUFFERS_BUILD_FLATHASH:BOOL=OFF
		-DFLATBUFFERS_BUILD_FLATLIB:BOOL=OFF
		-DFLATBUFFERS_BUILD_TESTS:BOOL=OFF
)
add_dependency_project_package(flatbuffers 1.9.0 ANY)

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
add_dependency_project_package(fmt 3.0.1)

ExternalProject_Add(freetype
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://download.savannah.gnu.org/releases/freetype/freetype-2.7.1.tar.gz
	URL_HASH SHA256=162ef25aa64480b1189cdb261228e6c5c44f212aac4b4621e28cf2157efb59f5
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(freetype 2.8)

ExternalProject_Add(fstrcmp
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://fstrcmp.sourceforge.net/fstrcmp-0.7.D001.tar.gz
	URL_HASH SHA256=e4018e850f80700acee8da296e56e15b1eef711ab15157e542e7d7e1237c3476
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(fstrcmp 0.7)

ExternalProject_Add(libcdio
	DEPENDS libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://ftp.gnu.org/gnu/libcdio/libcdio-0.94.tar.gz
	URL_HASH SHA256=96e2c903f866ae96f9f5b9048fa32db0921464a2286f5b586c0f02699710025a
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libcdio 0.94)

ExternalProject_Add(libfribidi
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://mirrors.kodi.tv/build-deps/sources/fribidi-0.19.7.tar.bz2
	URL_HASH SHA256=08222a6212bbc2276a2d55c3bf370109ae4a35b689acbc66571ad2a670595a8e
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libfribidi 0.19.7)

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
add_dependency_project_package(lzo2 2.09)

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
add_dependency_project_package(pcre 8.40)

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
add_dependency_project_package(sqlite 3170000)

ExternalProject_Add(taglib
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://taglib.org/releases/taglib-1.11.1.tar.gz
	URL_HASH SHA256=b6d1a5a610aae6ff39d93de5efd0fdc787aa9e9dc1e7026fa4c961b26563526b
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(taglib 1.11.1)

ExternalProject_Add(tinyxml
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://sourceforge.net/projects/tinyxml/files/tinyxml/2.6.2/tinyxml_2_6_2.tar.gz
	URL_HASH SHA256=15bdfdcec58a7da30adc87ac2b078e4417dbe5392f3afb719f9ba6d062645593
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(tinyxml 2.6.2)

add_custom_target(DependenciesRequired
	DEPENDS
		crossguid
		easyhook
		flatbuffers
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
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/freetype%3B%3B${PREFIX}/libfribidi%3B%3B${PREFIX}/libiconv
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(libass 0.13.6)

ExternalProject_Add(curl
	DEPENDS openssl zlib
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://curl.haxx.se/download/curl-7.61.1.tar.gz
	URL_HASH SHA256=eaa812e9a871ea10dbe8e1d3f8f12a64a8e3e62aeab18cb23742e2f1727458ae
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/openssl%3B%3B${PREFIX}/zlib
		-DBUILD_CURL_EXE:BOOL=OFF
		-DBUILD_CURL_TESTS:BOOL=OFF
		-DBUILD_SHARED_LIBS:BOOL=OFF
		-DBUILD_TESTING:BOOL=OFF
		-DCMAKE_USE_LIBSSH2:BOOL=OFF
		-DCMAKE_USE_OPENSSL:BOOL=ON
		-DCURL_CA_FALLBACK:BOOL=ON
		-DCURL_DISABLE_IMAP:BOOL=ON
		-DCURL_DISABLE_LDAP:BOOL=ON
		-DCURL_DISABLE_LDAPS:BOOL=ON
		-DCURL_DISABLE_POP3:BOOL=ON
		-DCURL_DISABLE_SMTP:BOOL=ON
		-DCURL_DISABLE_TELNET:BOOL=ON
		-DCURL_DISABLE_TELNET:BOOL=ON
		-DENABLE_MANUAL:BOOL=OFF
)
add_dependency_project_package(curl 7.61.1)

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
add_dependency_project_package(dnssd 765.50.9)

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
add_dependency_project_package(lcms2 2.8)

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
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/platform
)
add_dependency_project_package(libcec 4.0.2)

ExternalProject_Add(libgpg-error
	DEPENDS libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.36.tar.bz2
	URL_HASH SHA256=babd98437208c163175c29453f8681094bcaf92968a15cafb1a276076b33c97c
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv
)

ExternalProject_Add(libgcrypt
	DEPENDS libgpg-error libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.7.6.tar.bz2
	URL_HASH SHA256=626aafee84af9d2ce253d2c143dc1c0902dda045780cc241f39970fc60be05bc
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libgpg-error%3B%3B${PREFIX}/libiconv
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
	DEPENDS libgcrypt libgpg-error winflexbison libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL ftp://ftp.videolan.org/pub/videolan/libaacs/0.9.0/libaacs-0.9.0.tar.bz2
	URL_HASH SHA512=b9c658db22a0966486070d3b762509a7c0120469ab29d1e57c1b624cad309701de8b92455ec649db4d731be4a5c29c38fb4f99bb7617dbb4254270284a1903f6
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DBUILD_SHARED_LIBS:BOOL=ON
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libgcrypt%3B%3B${PREFIX}/libgpg-error%3B%3B${PREFIX}/winflexbison%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libaacs 0.9.0)

ExternalProject_Add(libbdplus
	DOWNLOAD_NAME libbdplus-45c76dd.tar.gz
	DEPENDS libgcrypt libgpg-error libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/ace20022/libbdplus/archive/45c76dd.tar.gz
	URL_HASH SHA256=843081a7fb05567f5d0ca8bbe69996f3cf18bf94e76871519aa8f2e598210f7f
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libgcrypt%3B%3B${PREFIX}/libgpg-error%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libbdplus 45c76dd)

ExternalProject_Add(libmicrohttpd
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.55.tar.gz
	URL_HASH SHA256=0c1cab8dc9f2588bd3076a28f77a7f8de9560cbf2d80e53f9a8696ada80ed0f8
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libmicrohttpd 0.9.55)

ExternalProject_Add(libnfs
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/sahlberg/libnfs/archive/libnfs-3.0.0.tar.gz
	URL_HASH SHA256=445d92c5fc55e4a5b115e358e60486cf8f87ee50e0103d46a02e7fb4618566a5
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libnfs 3.0.0)

ExternalProject_Add(libxml2
	DEPENDS libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL ftp://xmlsoft.org/libxml2/libxml2-2.9.4.tar.gz
	URL_HASH SHA256=ffb911191e509b966deb55de705387f14156e1a56b21824357cdf0053233633c
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff COMMAND
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(libxml2 2.9.4)

ExternalProject_Add(libxslt
	DEPENDS libiconv
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL ftp://xmlsoft.org/libxml2/libxslt-1.1.29.tar.gz
	URL_HASH SHA256=b5976e3857837e7617b29f2249ebb5eeac34e249208d31f1fbf7a6ba7a4090ce
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff COMMAND
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv%3B%3B${PREFIX}/libxml2
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(libxslt 1.1.29)

ExternalProject_Add(libplist
	DEPENDS libiconv libxml2
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL http://www.libimobiledevice.org/downloads/libplist-1.12.tar.bz2
	URL_HASH SHA256=0effdedcb3de128c4930d8c03a3854c74c426c16728b8ab5f0a5b6bdc0b644be
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv%3B%3B${PREFIX}/libxml2
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(libplist 1.12)

ExternalProject_Add(libwebp
	DOWNLOAD_NAME libwebp-0.6.0.tar.gz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/webmproject/libwebp/archive/v0.6.0.tar.gz
	URL_HASH SHA256=e1bd8b81098b8094edba0f161baf89f9fb1492e3fca19cf1d28eff4b88518702
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

ExternalProject_Add(mariadb-connector-c
	DEPENDS openssl
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://downloads.mariadb.com/Connectors/c/connector-c-3.0.6/mariadb-connector-c-3.0.6-src.tar.gz
	URL_HASH SHA256=2b2d18dc969dc385f7f740e4db112300e11bc626c9ba9aa05c284704095b9e48
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/openssl
		-DBUILD_SHARED_LIBS:BOOL=ON
		-DPLUGIN_AUTH_GSSAPI_CLIENT:STRING=OFF
		-DPLUGIN_DIALOG:STRING=STATIC
		-DPLUGIN_MYSQL_CLEAR_PASSWORD:STRING=STATIC
		-DPLUGIN_PVIO_NPIPE:STRING=STATIC
		-DPLUGIN_PVIO_SHMEM:STRING=STATIC
		-DPLUGIN_SHA256_PASSWORD:STRING=STATIC
		-DSKIP_TESTS:BOOL=ON
		-DWITH_CURL:BOOL=OFF
		-DWITH_MYSQLCOMPAT:BOOL=ON
		-DWITH_SSL:STRING=OPENSSL
		-DWITH_UNITTEST:BOOL=OFF
)
add_dependency_project_package(mariadb-connector-c 3.0.6)

ExternalProject_Add(libffi
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/libffi/libffi/archive/v3.3-rc1.tar.gz
	URL_HASH SHA256=87cbd612fa20f8eb7b91a3e996c5032b813644deee6c2d96724b50752296737e
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libffi 3.3.0)

ExternalProject_Add(python
	DEPENDS bzip2 openssl sqlite zlib expat libffi xz
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://www.python.org/ftp/python/3.7.5/Python-3.7.5.tgz
	URL_HASH MD5=1cd071f78ff6d9c7524c95303a3057aa
	PATCH_COMMAND
		COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/bzip2%3B%3B${PREFIX}/openssl%3B%3B${PREFIX}/sqlite%3B%3B${PREFIX}/zlib%3B%3B${PREFIX}/libffi%3B%3B${PREFIX}/xz%3B%3B${PREFIX}/expat
)
add_dependency_project_package(python 3.7.5)

ExternalProject_Add(libjpeg-turbo
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://sourceforge.net/projects/libjpeg-turbo/files/1.5.2/libjpeg-turbo-1.5.2.tar.gz
	URL_HASH SHA256=9098943b270388727ae61de82adec73cf9f0dbb240b3bc8b172595ebf405b528
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DENABLE_SHARED:BOOL=OFF
		-DINSTALL_DOC:BOOL=OFF
		-DWITH_JPEG8:BOOL=ON
		-DWITH_SIMD:BOOL=OFF
)

ExternalProject_Add(pillow
	DEPENDS freetype libjpeg-turbo python zlib
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://pypi.python.org/packages/55/aa/f7f983fb72710a9daa4b3374b7c160091d3f94f5c09221f9336ade9027f3/Pillow-4.2.1.tar.gz
	URL_HASH SHA256=c724f65870e545316f9e82e4c6d608ab5aa9dd82d5185e5b2e72119378740073
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/freetype%3B%3B${PREFIX}/libjpeg-turbo%3B%3B${PREFIX}/python%3B%3B${PREFIX}/zlib
)
add_dependency_project_package(pillow 4.2.1)

ExternalProject_Add(pycryptodome
	DEPENDS python
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://pypi.python.org/packages/2b/9b/aaa940ab8affd66eed043d69332dc607cddd68f9e399d93dcdfc8149fb21/pycryptodome-3.4.7.tar.gz
	URL_HASH SHA256=18d8dfe31bf0cb53d58694903e526be68f3cf48e6e3c6dfbbc1e7042b1693af7
	PATCH_COMMAND
		COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/python
		-DBUILD_SHARED_LIBS:BOOL=ON
		-DSEPARATE_NAMESPACE:BOOL=ON
)
add_dependency_project_package(pycryptodome 3.4.7)

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
add_dependency_project_package(shairplay ce80e00)

ExternalProject_Add(libbluray
	DEPENDS freetype libiconv libxml2
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL ftp://ftp.videolan.org/pub/videolan/libbluray/1.0.2/libbluray-1.0.2.tar.bz2
	URL_HASH SHA512=e1360ad08aa6cc67a80efa81a09004faebbe31105f1961494f82f655e3e7378b198ee3bc534b0d0c2bfec726939b11b545cc8bbfa30794fc647432dadf71089b
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/freetype%3B%3B${PREFIX}/libiconv%3B%3B${PREFIX}/libxml2
)
add_dependency_project_package(libbluray 1.0.1)
