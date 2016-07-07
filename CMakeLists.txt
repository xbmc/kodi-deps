cmake_minimum_required(VERSION 3.2)

project(kodi-deps)

#These have no dependencies so add these first
add_subdirectory(libs/zlib)
add_subdirectory(libs/crossguid)
add_subdirectory(libs/tinyxml)
add_subdirectory(libs/libiconv)
add_subdirectory(libs/lzo2)
add_subdirectory(libs/sqlite)
add_subdirectory(libs/yajl)
add_subdirectory(libs/taglib)
add_subdirectory(libs/pcre)
add_subdirectory(libs/python)


#depends on zlib
add_subdirectory(libs/openssl)

#depends on openssl
add_subdirectory(libs/curl)

#depends on openssl
add_subdirectory(libs/libssh)

add_subdirectory(libs/fribidi)
add_subdirectory(libs/freetype2)

add_subdirectory(libs/libass)
add_subdirectory()