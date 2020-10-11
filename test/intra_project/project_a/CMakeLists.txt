cmake_minimum_required(VERSION 3.9.4)

project(project_a VERSION 1.0.0)

# Optional
option(BUILD_DOCS ON)

# Custom .cmake includes
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../.." "${CMAKE_SOURCE_DIR}/../common")

# Doxygen related
find_package(Doxygen REQUIRED)
include(Doxytag)
include(DemoSettings)

include(GNUInstallDirs)
set(MODULE_INSTALL_DIR "${CMAKE_INSTALL_DATADIR}/cmake" CACHE PATH "Location of package configs")

# define one library
add_library(lib_a src/LibA.c)
target_include_directories(lib_a
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# install the library
install(
  TARGETS lib_a
  EXPORT project_a_targets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# install target import .cmake
install(
  EXPORT project_a_targets
  FILE project-a-targets.cmake
  DESTINATION "${MODULE_INSTALL_DIR}/${PROJECT_NAME}"
)

# install includes
install(
  DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include/"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

## GENERATE DOCUMENTATION

if(BUILD_DOCS)
  doxytag_add_docs(${PROJECT_NAME}-docs ALL
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
    INSTALL "${CMAKE_INSTALL_FULL_DOCDIR}"
  )
endif()

## ENABLE FIND_PACKAGE()

# generate package configuration
include(CMakePackageConfigHelpers)

configure_package_config_file(ProjectAConfig.cmake.in ProjectAConfig.cmake
  INSTALL_DESTINATION "${MODULE_INSTALL_DIR}/${PROJECT_NAME}"
  PATH_VARS
    CMAKE_INSTALL_INCLUDEDIR
    CMAKE_INSTALL_LIBDIR
)

write_basic_package_version_file(ProjectAVersion.cmake COMPATIBILITY SameMajorVersion)

install(
  FILES
    "${CMAKE_CURRENT_BINARY_DIR}/ProjectAConfig.cmake"
  DESTINATION "${MODULE_INSTALL_DIR}/${PROJECT_NAME}"
)
