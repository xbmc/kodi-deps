cmake_minimum_required(VERSION 3.4)

project(KodiDependencies LANGUAGES C)

cmake_policy(SET CMP0114 NEW)

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

add_custom_target(DependenciesRequired-zip)
function(add_dependency_project_package name version)
    # it's possible to pack dependency only if it was installed in separate folder
    if(FOLDER_PER_TARGET)
        set(hash_file "hashes")
        if(WINDOWS_STORE)
            set(hash_file "${hash_file}-win10")
        endif()
        set(hash_file "${hash_file}-$(Platform).txt")
        set(dep_name "${name}-${version}")
        string(TIMESTAMP date "%Y%m%d")
        if(NOT ANY IN_LIST ARGN)
            if(WINDOWS_STORE)
                set(dep_name "${dep_name}-win10")
            endif()
            set(dep_name "${dep_name}-$(Platform)-$(PlatformToolset)")
        endif()
        set(dep_name "${dep_name}-${date}")
        file(TO_NATIVE_PATH "${PREFIX}/../${dep_name}" zip_path)
        file(TO_NATIVE_PATH "${PREFIX}/${dep_name}" COPY_DESTINATION)
        file(TO_NATIVE_PATH "${PREFIX}/../${hash_file}" hash_path)

        ExternalProject_Add_Step(${name} zip
            COMMENT "Packaging '${name}'"
            DEPENDEES ${name}
            COMMAND ${CMAKE_COMMAND} -E copy_directory "${name}" "${COPY_DESTINATION}"
            COMMAND ${CMAKE_COMMAND} -E tar "cf" "${zip_path}.7z" --format=7zip -- "${COPY_DESTINATION}"
            COMMAND ${CMAKE_COMMAND} -E remove_directory "${COPY_DESTINATION}"
            COMMAND ${CMAKE_COMMAND} -Dhash_path=${hash_path} -Ddep_name=${dep_name} -Dzip_path=${zip_path} -P ${CMAKE_SOURCE_DIR}/zip.cmake
            WORKING_DIRECTORY ${PREFIX}
            ALWAYS TRUE
            EXCLUDE_FROM_MAIN TRUE
        )
        ExternalProject_Add_StepTargets(${name} zip)
        # ExternalProject_Add_StepDependencies(${name} zip ${name})
        add_dependencies(DependenciesRequired-zip ${name}-zip)
    endif()
endfunction()


# dependencies required by others

ExternalProject_Add(bzip2
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz
    URL_HASH SHA256=ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(bzip2 1.0.8)

ExternalProject_Add(expat
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/libexpat/libexpat/archive/R_2_8_3.tar.gz
    URL_HASH SHA256=533659a16e0184035a99fd8e783f1ad61a887a7bf8586a8681740b9d7ed42389
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    SOURCE_SUBDIR expat
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DEXPAT_BUILD_TESTS:BOOL=OFF
        -DEXPAT_BUILD_DOCS:BOOL=OFF
        -DEXPAT_BUILD_EXAMPLES:BOOL=OFF
        -DEXPAT_BUILD_TOOLS:BOOL=OFF
        -DEXPAT_SHARED_LIBS:BOOL=OFF
)
add_dependency_project_package(expat 2.8.3)

ExternalProject_Add(libiconv
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://ftp.gnu.org/gnu/libiconv/libiconv-1.19.tar.gz
    URL_HASH SHA256=88dd96a8c0464eca144fc791ae60cd31cd8ee78321e67397e25fc095c4a19aa6
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS:BOOL=OFF
)
add_dependency_project_package(libiconv 1.19)

ExternalProject_Add(openssl
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://www.openssl.org/source/openssl-3.5.8.tar.gz
    URL_HASH SHA256=a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(openssl 3.5.8)

ExternalProject_Add(zlib
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.gz
    URL_HASH SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DZLIB_BUILD_TESTING:BOOL=OFF
)
add_dependency_project_package(zlib 1.3.2)

ExternalProject_Add(xz
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/tukaani-project/xz/releases/download/v5.8.3/xz-5.8.3.tar.gz
    URL_HASH SHA256=3d3a1b973af218114f4f889bbaa2f4c037deaae0c8e815eec381c3d546b974a0
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DXZ_TOOL_XZ:BOOL=OFF
        -DXZ_TOOL_LZMAINFO:BOOL=OFF
        -DXZ_TOOL_XZDEC:BOOL=OFF
        -DXZ_TOOL_LZMADEC:BOOL=OFF
        -DXZ_DOC:BOOL=OFF
)
add_dependency_project_package(xz 5.8.3)

ExternalProject_Add(miniwdk
    GIT_REPOSITORY https://github.com/Paxxi/miniwdk
    GIT_TAG 2561ff58d73f16c4ee4beb6e25fa9c49026da115
    GIT_SHALLOW ON
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
# Causes miniwdk zip target to be added and it can't be built on github
#add_dependency_project_package(miniwdk 10.0.18362 ANY)

ExternalProject_Add(freetype
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://sourceforge.net/projects/freetype/files/freetype2/2.14.3/freetype-2.14.3.tar.xz
    URL_HASH SHA256=36bc4f1cc413335368ee656c42afca65c5a3987e8768cc28cf11ba775e785a5f
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(freetype 2.14.3)

ExternalProject_Add(fstrcmp
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://fstrcmp.sourceforge.net/fstrcmp-0.7.D001.tar.gz
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
    URL https://github.com/libcdio/libcdio/releases/download/2.3.0/libcdio-2.3.0.tar.bz2
    URL_HASH SHA256=53e83d284667535a767fd2d31edad1a6701591960459df373a10f1f21e80a7ed
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DBUILD_SHARED_LIBS:BOOL=ON
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libcdio 2.3.0)

ExternalProject_Add(libfribidi
    GIT_REPOSITORY https://github.com/thexai/fribidi
    GIT_TAG 29ca7f90e6117ccc8159ac751a5e533329e04530
    GIT_SHALLOW ON
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libfribidi 1.0.8)

ExternalProject_Add(harfbuzz
    DEPENDS freetype
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/harfbuzz/harfbuzz/releases/download/12.3.2/harfbuzz-12.3.2.tar.xz
    URL_HASH SHA256=6f6db164359a2da5a84ef826615b448b33e6306067ad829d85d5b0bf936f1bb8
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DHB_HAVE_DIRECTWRITE:BOOL=ON
        -DHB_HAVE_FREETYPE:BOOL=ON
        -DHB_BUILD_SUBSET:BOOL=OFF
        -DBUILD_SHARED_LIBS:BOOL=ON
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/freetype
)
add_dependency_project_package(harfbuzz 12.3.2)

ExternalProject_Add(sqlite
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://sqlite.org/2026/sqlite-amalgamation-3510300.zip
    URL_HASH SHA256=acb1e6f5d832484bf6d32b681e858c38add8b2acdfd42ac5df24b8afb46552b4
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(sqlite 3.51.3)

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


# Required, dyloaded deps
if(NOT WINDOWS_STORE)
ExternalProject_Add(detours
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/microsoft/Detours/archive/9764ceb/Detours-9764ceb.tar.gz
    URL_HASH SHA256=6c4397d5eab3372af971b18f5a07d61ad7a61ab7abecbcded4ce5381058e8313
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(detours 9764ceb)
endif()

if(NOT WINDOWS_STORE)
ExternalProject_Add(dnssd
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-2881.60.4.tar.gz
    URL_HASH SHA256=192b74fa5f4fdd985d6347bc2b39fed9b194c633f7cf7392f0a4c4d8b64c96a7
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(dnssd 2881.60.4)
endif()

ExternalProject_Add(libgpg-error
    DEPENDS libiconv
    GIT_REPOSITORY https://github.com/Paxxi/libgpg-error
    GIT_TAG 36ba2419cd42ca3b16b45d317fecb531ab23e3e0
    GIT_SHALLOW ON
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libgpg-error 1.36.0)

ExternalProject_Add(libgcrypt
    DEPENDS libgpg-error libiconv
    GIT_REPOSITORY https://github.com/Paxxi/libgcrypt
    GIT_TAG 7bb6e291fb112125d827cd1a75071ad4f6c3b704
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

ExternalProject_Add(libaacs
    DEPENDS libgcrypt libgpg-error winflexbison libiconv
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://download.videolan.org/pub/videolan/libaacs/0.11.1/libaacs-0.11.1.tar.bz2
    URL_HASH SHA256=a88aa0ebe4c98a77f7aeffd92ab3ef64ac548c6b822e8248a8b926725bea0a39
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DBUILD_SHARED_LIBS:BOOL=ON
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libgcrypt%3B%3B${PREFIX}/libgpg-error%3B%3B${PREFIX}/winflexbison%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libaacs 0.11.1)

ExternalProject_Add(libbdplus
    DEPENDS libgcrypt libgpg-error libiconv
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://download.videolan.org/pub/videolan/libbdplus/0.2.0/libbdplus-0.2.0.tar.bz2
    URL_HASH SHA256=b93eea3eaef33d6e9155d2c34b068c505493aa5a4936e63274f4342ab0f40a58
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libgcrypt%3B%3B${PREFIX}/libgpg-error%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libbdplus 0.2.0)

ExternalProject_Add(libxml2
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://download.gnome.org/sources/libxml2/2.15/libxml2-2.15.1.tar.xz
    URL_HASH SHA256=c008bac08fd5c7b4a87f7b8a71f283fa581d80d80ff8d2efd3b26224c39bc54c
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS:BOOL=ON
        -DLIBXML2_WITH_DEBUG:BOOL=OFF
        -DLIBXML2_WITH_ICONV:BOOL=OFF
        -DLIBXML2_WITH_MODULES:BOOL=OFF
        -DLIBXML2_WITH_PROGRAMS:BOOL=OFF
        -DLIBXML2_WITH_TESTS:BOOL=OFF
)
add_dependency_project_package(libxml2 2.15.1)

if(NOT WINDOWS_STORE)
ExternalProject_Add(libplist
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/libimobiledevice/libplist/releases/download/2.7.0/libplist-2.7.0.tar.bz2
    URL_HASH SHA256=7ac42301e896b1ebe3c654634780c82baa7cb70df8554e683ff89f7c2643eb8b
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(libplist 2.7.0)
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
    DEPENDS zlib
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.55.tar.gz
    URL_HASH SHA256=71a2c5b1218f60c4c6d2f1954c7eb20132156cae90bdb90b566c24db002782a6
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/zlib
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DPNG_TESTS:BOOL=OFF
        -DPNG_SHARED:BOOL=OFF
        -DPNG_TOOLS:BOOL=OFF
)
add_dependency_project_package(libpng 1.6.55)

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

ExternalProject_Add(libffi
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/libffi/libffi/archive/refs/tags/v3.4.4.tar.gz
    URL_HASH SHA256=828639972716ed18833df7b659b32060591fe0eb625a8d34078920d33c2dc867
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libffi 3.4.4)

ExternalProject_Add(zstd
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz
    URL_HASH SHA256=eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    SOURCE_SUBDIR build/cmake
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DZSTD_BUILD_STATIC:BOOL=ON
        -DZSTD_BUILD_DYNAMIC:BOOL=OFF
)
add_dependency_project_package(zstd 1.5.7)

ExternalProject_Add(python
    DEPENDS bzip2 openssl sqlite zlib expat libffi xz zstd
    GIT_REPOSITORY https://github.com/thexai/cpython
    GIT_TAG 44c9b4bf99579f5afa1800fd0b21e0c031b54a38
    GIT_SHALLOW ON
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/bzip2%3B%3B${PREFIX}/openssl%3B%3B${PREFIX}/sqlite%3B%3B${PREFIX}/zlib%3B%3B${PREFIX}/libffi%3B%3B${PREFIX}/xz%3B%3B${PREFIX}/expat%3B%3B${PREFIX}/zstd
)
add_dependency_project_package(python 3.14.7)

ExternalProject_Add(libjpeg-turbo
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.2.0/libjpeg-turbo-3.2.0.tar.gz
    URL_HASH SHA256=6f30092cef9fb839779646608f4ee14ae3cbac989c47fa05e841b0841f09878e
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DENABLE_SHARED:BOOL=OFF
        -DENABLE_STATIC:BOOL=ON
        -DWITH_JPEG8:BOOL=ON
        -DWITH_SIMD:BOOL=ON
        -DWITH_CRT_DLL:BOOL=ON
        -DWITH_TOOLS:BOOL=OFF
)
add_dependency_project_package(libjpeg-turbo 3.2.0)

ExternalProject_Add(pillow
    DEPENDS freetype libjpeg-turbo python zlib
    GIT_REPOSITORY https://github.com/thexai/Pillow
    GIT_TAG 8bb646fbdfbb8d3e680e855fb263fb4b083e275a
    GIT_SHALLOW ON
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/freetype%3B%3B${PREFIX}/libjpeg-turbo%3B%3B${PREFIX}/python%3B%3B${PREFIX}/zlib
)
add_dependency_project_package(pillow 12.3.0)

ExternalProject_Add(pycryptodome
    DEPENDS python
    GIT_REPOSITORY https://github.com/thexai/pycryptodome
    GIT_TAG 3801f6a9614724b7965352068bf6d4643a171707
    GIT_SHALLOW ON
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/python
        -DBUILD_SHARED_LIBS:BOOL=ON
        -DSEPARATE_NAMESPACE:BOOL=ON
)
add_dependency_project_package(pycryptodome 3.23.0)

if(NOT WINDOWS_STORE)
ExternalProject_Add(shairplay
    DOWNLOAD_NAME shairplay-096b61a.tar.gz
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/juhovh/shairplay/archive/096b61a.tar.gz
    URL_HASH SHA256=7e2b013ffe75ea2f13fb12b1aa38b8e2e8b1899ac292d57f05d7b352a3a181cf
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(shairplay 096b61a)
endif()

add_custom_target(DependenciesRequired
    DEPENDS
        bzip2
        expat
        freetype
        fstrcmp
        giflib
        harfbuzz
        libaacs
        libbdplus
        libcdio
        libffi
        libfribidi
        libgpg-error
        libgcrypt
        libjpeg-turbo
        libiconv
        libpng
        libwebp
        libxml2
        #miniwdk # WDK is not installed on github hosted runners
        openssl
        python
        pillow
        pycryptodome
        sqlite
        tinyxml
        winflexbison
        xz
        zlib
        zstd
)

add_custom_target(DependenciesRequiredDebug
    DEPENDS
        detours
        tinyxml
)

if(NOT WINDOWS_STORE)
add_dependencies(DependenciesRequired
    detours
    dnssd
    libplist
    shairplay
)
endif()
