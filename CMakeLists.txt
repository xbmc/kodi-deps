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

if(WINDOWS_STORE)
    # rust & cargo is only needed for libdovi on UWP build at present
    find_program(CARGO_EXECUTABLE cargo)

    if(NOT CARGO_EXECUTABLE)
        message(FATAL_ERROR "Cargo is required to build libdovi")
    endif()

    execute_process(
        COMMAND ${CARGO_EXECUTABLE} cbuild --help
        RESULT_VARIABLE CARGO_CBUILD_RESULT
        OUTPUT_QUIET
        ERROR_QUIET
    )

    if(NOT CARGO_CBUILD_RESULT EQUAL 0)
        message(FATAL_ERROR
            "libdovi requires cargo-c. Install it with "
            "'cargo install cargo-c' and ensure 'cargo cbuild' is available.")
    endif()
endif()

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
    URL https://github.com/libexpat/libexpat/archive/R_2_10_0.tar.gz
    URL_HASH SHA256=b3644a12f62d7762b62c444f69d169ba0234f13138d0240244bca64cbe35286f
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
add_dependency_project_package(expat 2.10.0)

ExternalProject_Add(libiconv
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://mirrors.kodi.tv/build-deps/sources/libiconv-1.19.1.tar.gz
    URL_HASH SHA256=9a06844846d664d7122161700c10a64480d7c7bcead3091925a785b38c91edab
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS:BOOL=OFF
)
add_dependency_project_package(libiconv 1.19.1)

ExternalProject_Add(openssl
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://www.openssl.org/source/openssl-3.5.9.tar.gz
    URL_HASH SHA256=603f5602e2eef00d77fbd429d34dcd5822bb301757a1bc9cdb24c670f1eb859a
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(openssl 3.5.9)

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
    URL https://sourceforge.net/projects/freetype/files/freetype2/2.15.0/freetype-2.15.0.tar.xz
    URL_HASH SHA256=93cd47eb719c325107f2d3cf087d06299e944c3b48a40b55537302304dea1dd5
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(freetype 2.15.0)

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

ExternalProject_Add(harfbuzz
    DEPENDS freetype
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/harfbuzz/harfbuzz/releases/download/15.2.0/harfbuzz-15.2.0.tar.xz
    URL_HASH SHA256=e2ec49090744383cdbe7df808c1cedaafba06a97be8dc4211fe546ba585f12cb
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DHB_HAVE_DIRECTWRITE:BOOL=ON
        -DHB_HAVE_FREETYPE:BOOL=ON
        -DHB_BUILD_SUBSET:BOOL=OFF
        -DHB_BUILD_RASTER:BOOL=OFF
        -DHB_BUILD_VECTOR:BOOL=OFF
        -DHB_BUILD_GPU:BOOL=OFF
        -DBUILD_SHARED_LIBS:BOOL=ON
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/freetype
)
add_dependency_project_package(harfbuzz 15.2.0)

ExternalProject_Add(sqlite
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://sqlite.org/2026/sqlite-amalgamation-3540100.zip
    URL_HASH SHA256=0a9c8e34352dad46006aa82836d5383bff9dc6bc9ce5a60553c05aa30e6ad1f9
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DBUILD_SHARED_LIBS:BOOL=ON
)
add_dependency_project_package(sqlite 3.54.1)

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
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.61.tar.bz2
    URL_HASH SHA256=7a85413f2bc354f4f8aa832b718af122e48965e9e0eb9012ee659c13c6385c93
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(libgpg-error 1.61)

ExternalProject_Add(libgcrypt
    DEPENDS libgpg-error
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.12.4.tar.bz2
    URL_HASH SHA256=d77f68f48879510e79a2f65977ccc68981781ea0923e5bdffac2a193ea3d660e
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libgpg-error
)
add_dependency_project_package(libgcrypt 1.12.4)

ExternalProject_Add(winflexbison
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/lexxmark/winflexbison/releases/download/v2.5.25/win_flex_bison-2.5.25.zip
    URL_HASH SHA256=8d324b62be33604b2c45ad1dd34ab93d722534448f55a16ca7292de32b6ac135
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/winflexbison.diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
)
add_dependency_project_package(winflexbison 2.5.25)

ExternalProject_Add(libaacs
    DEPENDS libgcrypt libgpg-error winflexbison libiconv
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://download.videolan.org/pub/videolan/libaacs/0.12.0/libaacs-0.12.0.tar.bz2
    URL_HASH SHA256=1996673a9fc45ee4a364c66ffa84756629bf3923e52346c7358b71becb8e4419
    PATCH_COMMAND ${PATCH} -p1 -i ${CMAKE_SOURCE_DIR}/patches/$(TargetName).diff
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DBUILD_SHARED_LIBS:BOOL=ON
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/libgcrypt%3B%3B${PREFIX}/libgpg-error%3B%3B${PREFIX}/winflexbison%3B%3B${PREFIX}/libiconv
)
add_dependency_project_package(libaacs 0.12.0)

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
    GIT_TAG 3f9ea616759ef8b24d3d1cc5b0cdcf7e29fc745a
    GIT_SHALLOW ON
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/bzip2%3B%3B${PREFIX}/openssl%3B%3B${PREFIX}/sqlite%3B%3B${PREFIX}/zlib%3B%3B${PREFIX}/libffi%3B%3B${PREFIX}/xz%3B%3B${PREFIX}/expat%3B%3B${PREFIX}/zstd
)
add_dependency_project_package(python 3.14.10)

ExternalProject_Add(libjpeg-turbo
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.2.1/libjpeg-turbo-3.2.1.tar.gz
    URL_HASH SHA256=c27ad72a68da151177929aa969ae773a2da5ac2af9ce946079314fdac8cece7f
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
add_dependency_project_package(libjpeg-turbo 3.2.1)

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
    GIT_TAG 4e1008c5faa479b9a40c98b36498da7599351f9f
    GIT_SHALLOW ON
    CMAKE_ARGS
        ${ADDITIONAL_ARGS}
        -DCMAKE_INSTALL_PREFIX:PATH=${INSTALL_PREFIX}
        -DCMAKE_PREFIX_PATH:PATH=${PREFIX}%3B%3B${PREFIX}/python
        -DBUILD_SHARED_LIBS:BOOL=ON
        -DSEPARATE_NAMESPACE:BOOL=ON
)
add_dependency_project_package(pycryptodome 3.24.1)

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

if(WINDOWS_STORE AND CARGO_EXECUTABLE)
file(WRITE "${CMAKE_BINARY_DIR}/libdovi-cargo-config.toml"
    "[unstable]\nbuild-std = [\"std\", \"panic_abort\"]\n"
)

ExternalProject_Add(libdovi
    DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/downloads
    URL https://github.com/quietvoid/dovi_tool/archive/refs/tags/libdovi-3.3.2.tar.gz
    URL_HASH SHA256=8ccb1922d7dbb57bc4f2c15c10b90c462f7a5f292efe317c116db923728dd3f1
    SOURCE_SUBDIR dolby_vision
    CONFIGURE_COMMAND
        ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/dolby_vision/.cargo
        COMMAND ${CMAKE_COMMAND} -E copy
            "${CMAKE_BINARY_DIR}/libdovi-cargo-config.toml"
            <SOURCE_DIR>/dolby_vision/.cargo/config.toml
    BUILD_COMMAND
        ${CARGO_EXECUTABLE} +nightly cbuild
        --release
        --features capi
        --target x86_64-uwp-windows-msvc
    INSTALL_COMMAND
        ${CARGO_EXECUTABLE} +nightly cinstall
        --release
        --features capi
        --target x86_64-uwp-windows-msvc
        --prefix "${INSTALL_PREFIX}"
    BUILD_IN_SOURCE TRUE
)
add_dependency_project_package(libdovi 3.3.2)
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
        libffi
        libgpg-error
        libgcrypt
        libjpeg-turbo
        libiconv
        libpng
        libwebp
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

if(WINDOWS_STORE AND CARGO_EXECUTABLE)
    add_dependencies(DependenciesRequired libdovi)
endif()

add_custom_target(DependenciesRequiredDebug
    DEPENDS
        detours
        tinyxml
)

if(NOT WINDOWS_STORE)
add_dependencies(DependenciesRequired
    detours
    dnssd
    shairplay
)
endif()
