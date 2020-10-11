cmake_minimum_required(VERSION 3.9.4)

project(project_b VERSION 1.0.0)

# Optional
option(BUILD_DOCS ON)

# Custom .cmake includes
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../.." "${CMAKE_SOURCE_DIR}/../common")

# Doxygen related
find_package(Doxygen REQUIRED)
include(Doxytag)
include(DemoSettings)

# import project after Doxytag!
if(NOT TARGET lib_a)
  find_package(ProjectA REQUIRED)
endif()

include(GNUInstallDirs)
set(MODULE_INSTALL_DIR "${CMAKE_INSTALL_DATADIR}/cmake" CACHE PATH "Location of package configs")

# define one library
add_library(lib_b src/LibB.c)
target_link_libraries(lib_b PUBLIC lib_a)
target_include_directories(lib_b
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# test: interface
add_library(intf_b INTERFACE)

# define one executable
add_executable(exec_b src/ExecB.c)
target_link_libraries(exec_b PRIVATE lib_b intf_b)

# install the library
install(
  TARGETS lib_b
  EXPORT project_b_targets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# install target import .cmake
install(
  EXPORT project_b_targets
  FILE project-b-targets.cmake
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
    DEPENDS "project_a-docs"
  )
endif()

## ENABLE FIND_PACKAGE()

# generate package configuration
include(CMakePackageConfigHelpers)

configure_package_config_file(ProjectBConfig.cmake.in ProjectBConfig.cmake
  INSTALL_DESTINATION "${MODULE_INSTALL_DIR}/${PROJECT_NAME}"
  PATH_VARS
    CMAKE_INSTALL_INCLUDEDIR
    CMAKE_INSTALL_LIBDIR
)

write_basic_package_version_file(ProjectBVersion.cmake COMPATIBILITY SameMajorVersion)

install(
  FILES
    "${CMAKE_CURRENT_BINARY_DIR}/ProjectBConfig.cmake"
  DESTINATION "${MODULE_INSTALL_DIR}/${PROJECT_NAME}"
)
