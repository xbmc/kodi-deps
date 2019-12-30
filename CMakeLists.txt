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

add_custom_target(zip)
function(add_dependency_project_package name version)
	# it's possible to pack dependency only if it was installed in separate folder
	if(FOLDER_PER_TARGET)
		set(dep_name "${name}-${version}")
		string(TIMESTAMP date "%Y%m%d")
		if(NOT ANY IN_LIST ARGN)
			if(WINDOWS_STORE)
				set(dep_name "${dep_name}-win10")
			endif()
			set(dep_name "${dep_name}-$(Platform)-$(PlatformToolset)")
		endif()
		set(dep_name "${dep_name}-${date}")
		file(TO_NATIVE_PATH "${PREFIX}/${dep_name}" COPY_DESTINATION)

		ExternalProject_Add_StepTargets(${name} zip)
		ExternalProject_Add_Step(${name} zip
			COMMENT "Packaging '${name}'"
			COMMAND ${CMAKE_COMMAND} -E copy_directory "${name}" "${COPY_DESTINATION}"
			COMMAND ${CMAKE_COMMAND} -E tar "cf" "${PREFIX}/../${dep_name}.7z" --format=7zip -- "${COPY_DESTINATION}"
			COMMAND ${CMAKE_COMMAND} -E remove_directory "${COPY_DESTINATION}"
			WORKING_DIRECTORY ${PREFIX}
			ALWAYS TRUE
			EXCLUDE_FROM_MAIN TRUE
		)
		ExternalProject_Add_StepDependencies(${name} zip ${name})
		add_dependencies(zip ${name}-zip)
	endif()
endfunction()


# Executables for build

if(NOT WINDOWS_STORE)
ExternalProject_Add(flatc
	GIT_REPOSITORY https://github.com/Paxxi/flatbuffers
	GIT_TAG ffb6b800354cbd6368da6bc6b8e937fa2d476ed2
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DFLATBUFFERS_BUILD_FLATHASH:BOOL=OFF
		-DFLATBUFFERS_BUILD_FLATLIB:BOOL=OFF
		-DFLATBUFFERS_BUILD_TESTS:BOOL=OFF
)
add_dependency_project_package(flatc 1.11.0)
endif()

# dependencies required by others

ExternalProject_Add(uwp_compat
	GIT_REPOSITORY https://github.com/Paxxi/uwp_compat
	GIT_TAG feb56bc2c4573b8657bba2b40648f0b2e2ecf72b
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_SHARED_LIBS:BOOL=OFF
)
add_dependency_project_package(uwp_compat 0.1)


ExternalProject_Add(bzip2
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://mirrors.kodi.tv/build-deps/sources/bzip2-1.0.6.tar.gz
	URL_HASH SHA256=a2848f34fcd5d6cf47def00461fcb528a0484d8edef8208d6d2e2909dc61d9cd
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	UPDATE_DISCONNECTED ON
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
	UPDATE_DISCONNECTED ON
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
	GIT_REPOSITORY https://github.com/Paxxi/libiconv
	GIT_TAG 88316873fbaa24c7dee0bbb739dbfaa2a51ddf20
	GIT_SHALLOW ON
	UPDATE_DISCONNECTED ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_SHARED_LIBS:BOOL=OFF
)
add_dependency_project_package(libiconv 1.16)

ExternalProject_Add(openssl
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://www.openssl.org/source/openssl-1.1.1d.tar.gz
	URL_HASH SHA256=1e3a91bc1f9dfce01af26026f856e064eab4c8ee0a8f457b5ae30b40b8b711f2
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(openssl 1.1.1d)

ExternalProject_Add(zlib
	GIT_REPOSITORY https://github.com/Paxxi/zlib
	GIT_TAG 1b8fe34fdd7b08da4629783d865df13dd2217bc8
	GIT_SHALLOW ON
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


ExternalProject_Add(miniwdk
	GIT_REPOSITORY https://github.com/Paxxi/miniwdk
	GIT_TAG 6f3dc9cba0e9879b7b4e20f8caabb89178c2aba2
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(miniwdk 10.0.18362 ANY)

ExternalProject_Add(crossguid
	GIT_REPOSITORY https://github.com/Paxxi/crossguid
	GIT_TAG 501320c7d43e232fbac11fe43741727a6e95754f
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DXG_TESTS:BOOL=OFF
)
add_dependency_project_package(crossguid 0.2.2)

ExternalProject_Add(flatbuffers
	GIT_REPOSITORY https://github.com/Paxxi/flatbuffers
	GIT_TAG ffb6b800354cbd6368da6bc6b8e937fa2d476ed2
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DFLATBUFFERS_BUILD_FLATC:BOOL=OFF
		-DFLATBUFFERS_BUILD_FLATHASH:BOOL=OFF
		-DFLATBUFFERS_BUILD_FLATLIB:BOOL=OFF
		-DFLATBUFFERS_BUILD_TESTS:BOOL=OFF
)
add_dependency_project_package(flatbuffers 1.11.0 ANY)

ExternalProject_Add(fmt
	GIT_REPOSITORY https://github.com/Paxxi/fmt
	GIT_TAG f12fbf1448b5a257047d507d31266e8e5529f25c
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DFMT_DOC:BOOL=OFF
		-DFMT_TEST:BOOL=OFF
)
add_dependency_project_package(fmt 6.1.2)

ExternalProject_Add(rapidjson
	GIT_REPOSITORY https://github.com/Paxxi/rapidjson
	GIT_TAG 908cba2b83105c5645f2fa4031c2b86e95b32f6f
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DRAPIDJSON_BUILD_TESTS:BOOL=OFF
		-DRAPIDJSON_BUILD_EXAMPLES:BOOL=OFF
		-DRAPIDJSON_BUILD_DOC:BOOL=OFF
)
add_dependency_project_package(rapidjson 1.1.0 ANY)

ExternalProject_Add(freetype
	GIT_REPOSITORY https://github.com/Paxxi/freetype2
	GIT_TAG 897622e64653268200feb867163bb9536b4e4950
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(freetype 2.10.1)

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
	GIT_REPOSITORY https://github.com/Paxxi/libcdio
	GIT_TAG 1a0d301021805dd3fbe6b8a861ebaa916d532421
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DBUILD_SHARED_LIBS:BOOL=ON
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libcdio 2.1.0)

ExternalProject_Add(libfribidi
	GIT_REPOSITORY https://github.com/Paxxi/fribidi
	GIT_TAG 15ff2bd79faf8d246eac7ea27b89393d1b905c8b
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libfribidi 1.0.8)

ExternalProject_Add(lzo2
	GIT_REPOSITORY https://github.com/Paxxi/lzo2
	GIT_TAG c04ee89a9b8c48b7a2661b3dbf79257453510c5a
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(lzo2 2.10)

ExternalProject_Add(pcre
	GIT_REPOSITORY https://github.com/Paxxi/pcre
	GIT_TAG 3addcafbdc621cec9b15d35caa78b14fe993b0b9
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
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
add_dependency_project_package(pcre 8.43)

ExternalProject_Add(sqlite
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://sqlite.org/2019/sqlite-amalgamation-3300100.zip
	URL_HASH SHA256=adf051d4c10781ea5cfabbbc4a2577b6ceca68590d23b58b8260a8e24cc5f081
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(sqlite 3300100)

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
if(NOT WINDOWS_STORE)
ExternalProject_Add(detours
	GIT_REPOSITORY https://github.com/Paxxi/Detours
	GIT_TAG 50aee6ed2bce729ce90c57c8f88d1802e6edda85
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(detours 64ec13)
endif()

ExternalProject_Add(libass
	DEPENDS freetype libfribidi libiconv
	GIT_REPOSITORY https://github.com/Paxxi/libass
	GIT_TAG 589761f828d38fb7099e3b859d6097f00bf68455
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/freetype%3B%3B${PREFIX}/libfribidi%3B%3B${PREFIX}/libiconv
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(libass 0.14.0)

ExternalProject_Add(brotli
	GIT_REPOSITORY https://github.com/Paxxi/brotli
	GIT_TAG 40b4519d55acc3ac76b2a6f573cca91ae2e12e45
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(brotli 1.0.7)

ExternalProject_Add(nghttp2
	DEPENDS openssl zlib
	GIT_REPOSITORY https://github.com/Paxxi/nghttp2
	GIT_TAG a3c6b3bbe7d56cebf4b019ca6f3f11f9ee0f83b2
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DENABLE_APP:BOOL=OFF
		-DENABLE_HPACK_TOOLS:BOOL=OFF
		-DENABLE_EXAMPLES:BOOL=OFF
		-DENABLE_LIB_ONLY:BOOL=ON
		-DENABLE_STATIC_LIB:BOOL=ON
		-DENABLE_SHARED_LIB:BOOL=OFF
		-DENABLE_DOC:BOOL=OFF
)
add_dependency_project_package(nghttp2 1.40.0)

ExternalProject_Add(curl
	DEPENDS openssl zlib brotli nghttp2
	GIT_REPOSITORY https://github.com/Paxxi/curl
	GIT_TAG 1b0fb07ad15eee4e8ec4afeb96a484c7d1c74ab6
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/openssl%3B%3B${PREFIX}/zlib%3B%3B${PREFIX}/brotli%3B%3B${PREFIX}/nghttp2
		-DBUILD_CURL_EXE:BOOL=OFF
		-DBUILD_CURL_TESTS:BOOL=OFF
		-DBUILD_SHARED_LIBS:BOOL=ON
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
		-DCURL_BROTLI:BOOL=ON
		-DENABLE_MANUAL:BOOL=OFF
		-DUSE_NGHTTP2:BOOL=ON
)
add_dependency_project_package(curl 7.67.0)

add_custom_target(DependenciesDllRequired
	DEPENDS
		curl
		libass
)


if(NOT WINDOWS_STORE)
ExternalProject_Add(dnssd
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-878.260.1.tar.gz
	URL_HASH SHA256=3cc71582e8eee469c2de8ecae1d769e7f32b3468dfb7f2ca77f1dee1f30a7d1e
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(dnssd 878.260.1)
endif()

ExternalProject_Add(lcms2
	GIT_REPOSITORY https://github.com/Paxxi/Little-CMS
	GIT_TAG 5c40d2402b4db97f6b91f83cfead6f28e14935f4
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(lcms2 2.9)

if(NOT WINDOWS_STORE)
ExternalProject_Add(platform
	GIT_REPOSITORY https://github.com/Paxxi/platform
	GIT_TAG 5f7ede279db7be840610eb6bc126068a735d7440
	GIT_SHALLOW ON
	GIT_SUBMODULES
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(platform 2.1.0)

ExternalProject_Add(libcec
	DEPENDS platform
	GIT_REPOSITORY https://github.com/Paxxi/libcec
	GIT_TAG 59ab401c5a89e9ea20269b4e4747240632665811
	GIT_SHALLOW ON
	GIT_SUBMODULES
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/platform
)
add_dependency_project_package(libcec 4.0.4)
endif()

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
add_dependency_project_package(libgpg-error 1.36.0)

ExternalProject_Add(libgcrypt
	DEPENDS libgpg-error libiconv
	GIT_REPOSITORY https://github.com/Paxxi/libgcrypt
	GIT_TAG db592119e0e86ae1043b5c92f1e7a64c8c4759ca
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libgpg-error%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libgcrypt 1.8.5)

ExternalProject_Add(winflexbison
	DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
	URL https://github.com/lexxmark/winflexbison/releases/download/v2.5.20/win_flex_bison-2.5.20.zip
	URL_HASH SHA256=8d751f31eb8d79251d809f37bb0d853d72f58a21c5f672d5e31f35b4d97b31fe
	PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/winflexbison.diff
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(winflexbison 2.5.20)

if(NOT WINDOWS_STORE)
ExternalProject_Add(swig
	DEPENDS pcre winflexbison
	GIT_REPOSITORY https://github.com/Paxxi/swig
	GIT_TAG 6648e55065829d55010a24b62eb254b36e40cbbc
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/pcre%3B%3B${PREFIX}/winflexbison
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(swig 4.0.1)
endif()

ExternalProject_Add(libaacs
	DEPENDS libgcrypt libgpg-error winflexbison libiconv
	GIT_REPOSITORY https://github.com/Paxxi/libaacs
	GIT_TAG 73e359646f4fd5a689c77f066a3e78eed7a0157a
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DBUILD_SHARED_LIBS:BOOL=ON
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libgcrypt%3B%3B${PREFIX}/libgpg-error%3B%3B${PREFIX}/winflexbison%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libaacs 0.9.0)

ExternalProject_Add(libbdplus
	DEPENDS libgcrypt libgpg-error libiconv uwp_compat
	GIT_REPOSITORY https://github.com/Paxxi/libbdplus
	GIT_TAG c37157774aaaf5a1002474c17d966c4d0996b889
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libgcrypt%3B%3B${PREFIX}/libgpg-error%3B%3B${PREFIX}/libiconv%3B%3B${PREFIX}/uwp_compat
)
add_dependency_project_package(libbdplus 0.1.2)

ExternalProject_Add(libmicrohttpd
	GIT_REPOSITORY https://github.com/Paxxi/libmicrohttpd
	GIT_TAG 3ef6844ec76d867a2188a345938643653f837209
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libmicrohttpd 0.9.69)

ExternalProject_Add(libnfs
	GIT_REPOSITORY https://github.com/Paxxi/libnfs
	GIT_TAG 9b6f9cb05c753e223c8e4555ca8d6508f9f00312
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libnfs 4.0.0)

ExternalProject_Add(libxml2
	DEPENDS libiconv
	GIT_REPOSITORY https://github.com/Paxxi/libxml2
	GIT_TAG c9e6dae59f576f0e40dbef5d52f11b3de00e8a7d
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(libxml2 2.9.9)

ExternalProject_Add(libxslt
	DEPENDS libiconv libxml2 uwp_compat
	GIT_REPOSITORY https://github.com/Paxxi/libxslt
	GIT_TAG f63869008f803398f86697031201f83812d65732
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv%3B%3B${PREFIX}/libxml2%3B%3B${PREFIX}/uwp_compat
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(libxslt 1.1.34)

if(NOT WINDOWS_STORE)
ExternalProject_Add(libplist
	DEPENDS libiconv libxml2
	GIT_REPOSITORY https://github.com/Paxxi/libplist
	GIT_TAG 36aeb3bb94bc5d25978ed212929e8e2adeba0257
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv%3B%3B${PREFIX}/libxml2
		-DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(libplist 2.1.0)
endif()

ExternalProject_Add(giflib
	GIT_REPOSITORY https://github.com/Paxxi/giflib
	GIT_TAG 9dfce00d4de675ee813d4bb95b59a5b189bb1f1c
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)

add_dependency_project_package(giflib 5.2.1)

ExternalProject_Add(libpng
	GIT_REPOSITORY https://github.com/Paxxi/libpng
	GIT_TAG e49a9a21ddbd39f84b7819f78317b60c89c9b0e8
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/zlib
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DPNG_TESTS:BOOL=OFF
		-DPNG_SHARED:BOOL=OFF
)

add_dependency_project_package(libpng 1.6.37)

ExternalProject_Add(libwebp
	DEPENDS zlib
	GIT_REPOSITORY https://github.com/Paxxi/libwebp
	GIT_TAG 9b8da9837f804149394960b9a4e3226762960723
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/zlib
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DWEBP_BUILD_ANIM_UTILS=OFF
		-DWEBP_BUILD_CWEBP=OFF
		-DWEBP_BUILD_DWEBP=OFF
		-DWEBP_BUILD_GIF2WEBP=OFF
		-DWEBP_BUILD_IMG2WEBP=OFF
		-DWEBP_BUILD_VWEBP=OFF
		-DWEBP_BUILD_WEBPINFO=OFF
		-DWEBP_BUILD_WEBPMUX=OFF
		-DWEBP_BUILD_EXTRAS=OFF
)

add_dependency_project_package(libwebp 1.0.3)

ExternalProject_Add(mariadb-connector-c
	DEPENDS openssl uwp_compat
	GIT_REPOSITORY https://github.com/Paxxi/mariadb-connector-c
	GIT_TAG 30788c5b2624ace29063918d71e0625c32c2ee93
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/openssl%3B%3B${PREFIX}/uwp_compat
		-DBUILD_SHARED_LIBS:BOOL=ON
		-DPLUGIN_AUTH_GSSAPI_CLIENT:STRING=OFF
		-DPLUGIN_DIALOG:STRING=STATIC
		-DPLUGIN_MYSQL_CLEAR_PASSWORD:STRING=STATIC
		-DPLUGIN_PVIO_NPIPE:STRING=STATIC
		-DPLUGIN_PVIO_SHMEM:STRING=STATIC
		-DPLUGIN_SHA256_PASSWORD:STRING=STATIC
		-DPLUGIN_CLIENT_ED25519:STRING=STATIC
		-DPLUGIN_CACHING_SHA2_PASSWORD:STRING=STATIC
		-DWITH_CURL:BOOL=OFF
		-DWITH_MYSQLCOMPAT:BOOL=ON
		-DWITH_SSL:STRING=OPENSSL
		-DWITH_UNIT_TESTS:BOOL=OFF
)
add_dependency_project_package(mariadb-connector-c 3.1.6)

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
	GIT_REPOSITORY https://github.com/Paxxi/cpython
	GIT_TAG d53334ac7bc6856f389c4820e3aba850f2cd4488
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/bzip2%3B%3B${PREFIX}/openssl%3B%3B${PREFIX}/sqlite%3B%3B${PREFIX}/zlib%3B%3B${PREFIX}/libffi%3B%3B${PREFIX}/xz%3B%3B${PREFIX}/expat
)
add_dependency_project_package(python 3.7.5)

ExternalProject_Add(libjpeg-turbo
	GIT_REPOSITORY https://github.com/Paxxi/libjpeg-turbo
	GIT_TAG 5f1f82cbe87427c0844cdaa91c9437aa8f08f6fd
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DENABLE_SHARED:BOOL=OFF
		-DENABLE_STATIC:BOOL=ON
		-DWITH_JPEG8:BOOL=ON
		-DWITH_SIMD:BOOL=OFF
		-DWITH_CRT_DLL:BOOL=ON
)

add_dependency_project_package(libjpeg-turbo 2.0.3)

ExternalProject_Add(pillow
	DEPENDS freetype libjpeg-turbo python zlib
	GIT_REPOSITORY https://github.com/Paxxi/pillow
	GIT_TAG 6d9a126b48ddb2d5be6a9eb8fc6b6a978aef144a
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/freetype%3B%3B${PREFIX}/libjpeg-turbo%3B%3B${PREFIX}/python%3B%3B${PREFIX}/zlib
)
add_dependency_project_package(pillow 6.2.1)

ExternalProject_Add(pycryptodome
	DEPENDS python
	GIT_REPOSITORY https://github.com/Paxxi/pycryptodome
	GIT_TAG 8d25489b7d0fd0a9e086331a20b4aa7175421076
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/python
		-DBUILD_SHARED_LIBS:BOOL=ON
		-DSEPARATE_NAMESPACE:BOOL=ON
)
add_dependency_project_package(pycryptodome 3.9.4)

if(NOT WINDOWS_STORE)
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
endif()

ExternalProject_Add(libudfread
	GIT_REPOSITORY https://github.com/Paxxi/libudfread
	GIT_TAG 629abc253fc0ffc85ba873e1dfa487b05de808cc
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libudfread 1.0.0)


ExternalProject_Add(libbluray
	DEPENDS freetype libiconv libxml2 libudfread libaacs
	GIT_REPOSITORY https://github.com/Paxxi/libbluray
	GIT_TAG dc096e2171e732275b8b25a4f7ef0fed53a172bb
	GIT_SHALLOW ON
	CMAKE_ARGS
		${ADDITIONAL_ARGS}
		-DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
		-DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/freetype%3B%3B${PREFIX}/libiconv%3B%3B${PREFIX}/libxml2%3B%3B${PREFIX}/libudfread
)
add_dependency_project_package(libbluray 1.1.2)
