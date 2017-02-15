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
