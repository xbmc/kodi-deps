cmake_minimum_required(VERSION 3.2)

project(kodi-deps)

set(BUILD_TOOLS OFF)
set(BUILD_EXAMPLES OFF)
set(BUILD_TESTS OFF)
set(BUILD_TEST OFF)
set(UNIFIED_BUILD ON)
set(BUILD_SHARED_LIBS ON)

message(${CMAKE_SIZEOF_VOID_P})

#These have no dependencies so add these first
add_subdirectory(libs/zlib)
set(BUILD_SHARED_LIBS OFF)
add_subdirectory(libs/crossguid)
add_subdirectory(libs/tinyxml)
add_subdirectory(libs/libiconv)
add_subdirectory(libs/lzo2)

set(BUILD_SHARED_LIBS ON)
add_subdirectory(libs/sqlite)
add_subdirectory(libs/yajl)

set(BUILD_SHARED_LIBS OFF)
add_subdirectory(libs/taglib)


set(PCRE_SUPPORT_JIT ON)
set(PCRE_SUPPORT_UTF ON)
set(PCRE_BUILD_TESTS OFF)
set(PCRE_BUILD_PCREGREP OFF)
set(PCRE_SHOW_REPORT OFF)
set(PCRE_NEWLINE "ANYCRLF")
add_subdirectory(libs/pcre)

set(BUILD_SHARED_LIBS ON)
add_subdirectory(libs/python)

add_subdirectory(libs/expat/expat)

set(WITH_ZLIB_BUNDLED OFF)
add_subdirectory(libs/mysql-connector-c)
add_subdirectory(libs/libodb)
add_subdirectory(libs/libodb-mysql)
add_subdirectory(libs/libodb-sqlite)


add_subdirectory(libs/giflib)
add_subdirectory(libs/libcdio)
# set(BUILD_SHARED_LIBS OFF)
# add_subdirectory(libs/p8-platform)

# set(BUILD_SHARED_LIBS ON)
# add_subdirectory(libs/libcec)

add_subdirectory(libs/libmicrohttpd)
add_subdirectory(libs/libnfs)

set(BUILD_SHARED_LIBS OFF)
add_subdirectory(libs/libplist)

set(BUILD_SHARED_LIBS ON)
add_subdirectory(libs/libpng)

set(BUILD_TOOLS OFF)
set(BUILD_TESTS OFF)
set(BUILD_CONTRIB OFF)
set(BUILD_MANUAL OFF)
set(BUILD_HTML OFF)
add_subdirectory(libs/libtiff)
# webp has no install step as of now
#add_subdirectory(libs/libwebp)

add_subdirectory(libs/Little-CMS)
add_subdirectory(libs/mDNSResponder)
add_subdirectory(libs/openjpeg)
add_subdirectory(libs/shairplay)
add_subdirectory(libs/xz)


#depends on zlib
# add_subdirectory(libs/openssl)

#depends on iconv
add_subdirectory(libs/libxml2)
add_subdirectory(libs/libxslt)

#depends on openssl
# add_subdirectory(libs/curl)
# add_subdirectory(libs/libssh)

set(BUILD_SHARED_LIBS OFF)
add_subdirectory(libs/fribidi)
add_subdirectory(libs/freetype2)
add_subdirectory(libs/libbluray)

set(BUILD_SHARED_LIBS ON)
add_subdirectory(libs/libass)
# add_subdirectory()