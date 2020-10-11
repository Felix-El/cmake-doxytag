###############################################################################
#                                  DOXYTAG
#      A Doxygen wrapper for easy documentation linking across projects
###############################################################################
# Copyright (c) 2020, Felix Lelchuk
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# 
# * Neither the name of Kitware, Inc. nor the names of Contributors
#   may be used to endorse or promote products derived from this
#   software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###############################################################################

set(DOXYTAG_SUFFIX ".doxytags" CACHE STRING "Suffix for Doxygen tagfiles")

# DOXYTAG_ADD_DOCS(... [DEPENDS target1 [target2 ...]] [ALL] [INSTALL])
# --------------------------------------------------------------------------------------
# Creates a custom Doxytag target using doxygen_add_docs() managing tagfiles
# across dependencies.
#
# The arguments abbreviated ... are the same as are passed to doxygen_add_docs().
# In order to link to other documentation (other Doxytag targets), list the other
# Doxytag targets (own or imported) as DEPENDS.
# Additionally this macro supports the ALL switch even if the underlying
# doxygen_add_docs() does not.
# If the documentation is intended to be installed, set the INSTALL option.
#
# Linking external documentation is supported through Doxygen's TAGFILES feature.
# For this to work, this macro
#   - sets DOXYGEN_GENERATE_HTML to YES
#   - sets DOXYGEN_TAGFILES to be the union of all TAGFILES contributed by
#     DEPENDS targets
#   - sets DOXYGEN_GENERATE_TAGFILE to the target name followed by DOXYTAG_SUFFIX
#
# With the Doxytag target created, it can become a dependency of another Doxytag target,
# be it between Doxytags in the same CMake project or across CMake projects by using
# DOXYTAG_EXPORT().
########################################################################################
macro(DOXYTAG_ADD_DOCS)
  # parse arguments
  set(_options ALL)
  set(_one_value_args INSTALL)
  set(_multi_value_args DEPENDS)
  cmake_parse_arguments(_args
                        "${_options}"
                        "${_one_value_args}"
                        "${_multi_value_args}"
                        ${ARGN})

  if(_args_UNPARSED_ARGUMENTS)
    list(GET _args_UNPARSED_ARGUMENTS 0 _target)
  else()
    message(FATAL "A TARGET argument is required")
  endif()

  if(DOXYGEN_FOUND)
    set(_tagfile "${_target}${DOXYTAG_SUFFIX}")
    set(_tagexport "${CMAKE_CURRENT_BINARY_DIR}/${_tagfile}")
    
    # DOXYGEN_OUTPUT_DIRECTORY is given relative to CMAKE_CURRENT_BINARY_DIR
    if(DOXYGEN_OUTPUT_DIRECTORY)
      get_filename_component(_docbuilddir "${DOXYGEN_OUTPUT_DIRECTORY}" ABSOLUTE BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    else()
      set(_docbuilddir "${CMAKE_CURRENT_BINARY_DIR}")
    endif()

    set(_tagimports)
    foreach(_dep ${_args_DEPENDS})
      get_property(_deptags TARGET ${_dep} PROPERTY DOXYTAG_TAGFILES)
      list(APPEND _tagimports ${_deptags})
    endforeach()

    set(DOXYGEN_GENERATE_HTML YES)
    set(DOXYGEN_GENERATE_TAGFILE ${_tagexport})
    set(DOXYGEN_TAGFILES ${_tagimports})

    doxygen_add_docs(${_args_UNPARSED_ARGUMENTS})
    set_property(TARGET ${_target} PROPERTY DOXYTAG_IS_TARGET TRUE)

    # ensure build order for intra-project dependencies
    if(_args_DEPENDS)
      add_dependencies(${_target} ${_args_DEPENDS})
    endif()
    
    # doxygen_add_docs(... ALL ...) not supported in older cmake
    if(_args_ALL)
      set_property(TARGET ${_target} PROPERTY EXCLUDE_FROM_ALL FALSE)
    endif()

    if(_args_INSTALL)
      # We aim to install the documentation. Paths used must be the final installation paths.
      list(APPEND _tagimports "${_tagexport}=${_args_INSTALL}")

      # schedule installation steps for our documentation itself and our tagfile
      install(FILES ${_tagexport} DESTINATION ${_args_INSTALL})
      install(DIRECTORY "${_docbuilddir}/html/" DESTINATION ${_args_INSTALL})
    else()
      # Documentation will only be kept in the build space, no installation
      list(APPEND _tagimports "${_tagexport}=${_docbuilddir}")
    endif()

    list(REMOVE_DUPLICATES _tagimports)
    set_property(TARGET ${_target} PROPERTY DOXYTAG_TAGFILES ${_tagimports})
  else()
    message(FATAL "Doxygen needs to be available to generate documentation")
  endif()
endmacro()

# DOXYTAG_EXPORT(TARGETS target1 [target2 ...] FILE file DESTINATION dir [NAMESPACE ns])
# --------------------------------------------------------------------------------------
# Generates and installs a CMake file containing code to import Doxytag TARGETS
# from the installation tree into another project, similar to install(EXPORT).
#
# The generated and installed CMake file is supposed to be included from the
# <project>-config.cmake.in, typically configured and installed using the
# configure_package_config_file() macro.
########################################################################################
macro(DOXYTAG_EXPORT)
  # parse arguments
  set(_options NO_INSTALL)
  set(_one_value_args DESTINATION NAMESPACE FILE)
  set(_multi_value_args TARGETS)
  cmake_parse_arguments(_args
                        "${_options}"
                        "${_one_value_args}"
                        "${_multi_value_args}"
                        ${ARGN})

  if(_args_UNPARSED_ARGUMENTS)
    message(FATAL "Unparsed arguments remain")
  elseif(NOT _args_TARGETS)
    message(FATAL "At least one target in TARGETS expected")
  elseif(NOT _args_DESTINATION)
    message(FATAL "A DESTINATION must be set")
  elseif(NOT _args_FILE)
    message(FATAL "A FILE must be set")
  endif()

  set(_contents "# Auto-generated by FindDoxytag.cmake\n\n")
  foreach(_target ${_args_TARGETS})
    get_property(_is_doxytag_target TARGET ${_target} PROPERTY DOXYTAG_IS_TARGET)
    if(_is_doxytag_target)
      get_property(_target_tags TARGET ${_target} PROPERTY DOXYTAG_TAGFILES)

      string(APPEND _contents "add_custom_target(${_args_NAMESPACE}${_target})\n")
      string(APPEND _contents "set_property(TARGET ${_args_NAMESPACE}${_target} PROPERTY DOXYTAG_IS_TARGET TRUE)\n")
      string(APPEND _contents "set_property(TARGET ${_args_NAMESPACE}${_target} PROPERTY DOXYTAG_TAGFILES \"${_target_tags}\")\n\n")
    else()
      message(WARNING "Target ${_target} is not a Doxytag target")
    endif()
  endforeach()

  file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${_args_FILE}" CONTENT "${_contents}")
endmacro()
