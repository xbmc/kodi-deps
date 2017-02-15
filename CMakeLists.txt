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
