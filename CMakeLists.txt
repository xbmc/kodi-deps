cmake_minimum_required(VERSION 3.2)

project(kodi-deps)

set(BUILD_TOOLS OFF)
set(BUILD_EXAMPLES OFF)
set(BUILD_TESTS OFF)
set(BUILD_TEST OFF)
set(UNIFIED_BUILD ON)

message(${CMAKE_SIZEOF_VOID_P})

#These have no dependencies so add these first
add_subdirectory(libs/zlib)
add_subdirectory(libs/crossguid)
add_subdirectory(libs/tinyxml)
add_subdirectory(libs/libiconv)
# add_subdirectory(libs/lzo2)
add_subdirectory(libs/sqlite)
add_subdirectory(libs/yajl)
# add_subdirectory(libs/taglib)
# add_subdirectory(libs/pcre)
# add_subdirectory(libs/python)


#depends on zlib
# add_subdirectory(libs/openssl)

#depends on iconv
add_subdirectory(libs/libxml2)
add_subdirectory(libs/libxslt)

#depends on openssl
# add_subdirectory(libs/curl)

#depends on openssl
# add_subdirectory(libs/libssh)

set(BUILD_SHARED_LIBS OFF)
add_subdirectory(libs/fribidi)
add_subdirectory(libs/freetype2)

set(BUILD_SHARED_LIBS ON)
add_subdirectory(libs/libass)
# add_subdirectory()