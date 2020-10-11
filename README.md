<!-- omit in toc -->
# Doxytag.cmake

A user-friendly `FindDoxygen.cmake` wrapper that helps you link Doxygen documentation across projects.

- [About](#about)
- [Two-Project Example](#two-project-example)
  - [Project A](#project-a)
  - [Project B](#project-b)
- [Conclusion](#conclusion)

## About

Doxygen is a well-known and commonly used documentation generator that has been
integrated with CMake for many years. While `FindDoxygen.cmake` covers most of
what you might ever need from Doxygen, it does not provide a direct way to
link related projects' documentation. This is where `Doxytag.cmake` can help.

The ability to link HTML documentation is a feature of Doxygen itself. A `Doxyfile`
can specifcy the variable `GENERATE_TAGFILE` to export a tagfile and/or
`TAGFILES` to import existing tagfiles.
These variables have been long accessible for direct manipulation through the Doxygen
CMake module. However, with a growing number of projects it becomes a pain to
keep track of which tagfiles to include from which location and where the corresponding
HTML documentation resides.

The `Doxytag.cmake` module brings in two macros which help you takle this problem
the CMake way - using targets and dependencies between them.

Just like you are used to define a library (target) in one project and link to it from
another, you will be able to create a Doxytag target in one project and link to it
from another Doxytag target.

## Two-Project Example

Let's look at how to link a hypothetical `ProjectB` to `ProjectA` documentation-wise.

### Project A

        project(ProjectA)

1. Import Doxygen and include Doxytag early in your `CMakeLists.txt`.

        find_package(Doxygen REQUIRED)
        include(Doxytag)

2. Create a Doxytag target using `doxytag_add_docs()`.

        doxytag_add_docs(ALL        # ALL: include doc generation in 'all' target
            docs                    # name our Doxytag target
            include src             # files/directories for Doxygen to document
            INSTALL "share/doc/${PROJECT_NAME}"
        )

    This will build the documentation and export a tagfile, however has only few benefits over `doxygen_add_docs()` until we make use of that.

3. Export the Doxytag targets for downstream projects. We begin by having Doxytag generate part of the export config for us and install it to the prefix.

        doxytag_export(
            TARGETS docs
            FILE doxytags.cmake
            DESTINATION "share/cmake/${PROJECT_NAME}"
            NAMESPACE "${PROJECT_NAME}"
        )

Since this export config needs to be read by downstream projects, we have to make sure it gets included:

        include(CMakePackageConfigHelpers)
        configure_package_config_file(
            ProjectAConfig.cmake.in
            ProjectAConfig.cmake
            INSTALL_DESTINATION "share/cmake/${PROJECT_NAME}"
        )
        install(
            FILES
                "${CMAKE_CURRENT_BINARY_DIR}/ProjectAConfig.cmake"  # entrypoint for find_package
                "${CMAKE_CURRENT_BINARY_DIR}/doxytags.cmake"        # Doxytags targets
                # ... more configs ...
            DESTINATION "share/cmake/${PROJECT_NAME}"
        )

Your template file `ProjectAConfig.cmake.in` will roughly look like this:

        @PACKAGE_INIT@

        set(ProjectA_VERSION_MAJOR "@PROJECT_VERSION_MAJOR@")
        set(ProjectA_VERSION_MINOR "@PROJECT_VERSION_MINOR@")
        set(ProjectA_VERSION_PATCH "@PROJECT_VERSION_PATCH@")

        # include(...targets.cmake)
        include("${CMAKE_CURRENT_LIST_DIR}/doxytags.cmake")

This way, `find_package(ProjectA)` causes CMake to include `ProjectAConfig.cmake` into a downstream
project, which in turn includes our config of exported Doxytag targets.

We are done with ProjectA here, let's move on.

### Project B

Assuming ProjectA is built and installed at this time and that ProjectA's installation prefix is
known to ProjectB, we can continue.

    project(ProjectB)

1. Import Doxygen and include Doxytag early in your `CMakeLists.txt`.

        find_package(Doxygen REQUIRED)
        include(Doxytag)

2. Import upstream project:

        find_package(ProjectA)

3. Create a Doxytag target using `doxytag_add_docs()`. This time we have a dependency.

        doxytag_add_docs(ALL        # ALL: include doc generation in 'all' target
            docs                    # name our Doxytag target
            include src             # files/directories for Doxygen to document
            INSTALL "share/doc/${PROJECT_NAME}"
            DEPENDS ProjectA::docs
        )

    This will build the documentation for ProjectB, setting up the DOXYGEN_TAGFILES variable
    correctly for Doxygen to find ProjectA's tagfiles, linking the documentation as we want it to.
    Steps from here are same for ProjectB as they were for ProjectA.

4. Export the Doxytag targets for downstream projects. Same as for ProjectA.

        doxytag_export(
            TARGETS docs
            FILE doxytags.cmake
            DESTINATION "share/cmake/${PROJECT_NAME}"
            NAMESPACE "${PROJECT_NAME}"
        )

Since this export config needs to be read by downstream projects, we have to make sure it gets included:

        include(CMakePackageConfigHelpers)
        configure_package_config_file(
            ProjectBConfig.cmake.in
            ProjectBConfig.cmake
            INSTALL_DESTINATION "share/cmake/${PROJECT_NAME}"
        )
        install(
            FILES
                "${CMAKE_CURRENT_BINARY_DIR}/ProjectBConfig.cmake"  # entrypoint for find_package
                "${CMAKE_CURRENT_BINARY_DIR}/doxytags.cmake"        # Doxytags targets
                # ... more configs ...
            DESTINATION "share/cmake/${PROJECT_NAME}"
        )

`ProjectBConfig.cmake` would look much like `ProjectAConfig.cmake`. And we are done with ProjectB.

## Conclusion

As seen in the example, linking documentations from related projects is done as easily as specifying upstream targets as dependencies in a single macro call. The locations of HTML files and tag files are kept as properties of Doxytag targets - the user does not have to deal with them.

Check the `test` subdirectory for some minimal examples.
