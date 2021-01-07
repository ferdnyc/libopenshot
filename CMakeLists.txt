####################### CMakeLists.txt (libopenshot) #########################
# @brief CMake build file for libopenshot (used to generate makefiles)
# @author Jonathan Thomas <jonathan@openshot.org>
#
# @section LICENSE
#
# Copyright (c) 2008-2019 OpenShot Studios, LLC
# <http://www.openshotstudios.com/>. This file is part of
# OpenShot Library (libopenshot), an open-source project dedicated to
# delivering high quality video editing and animation solutions to the
# world. For more information visit <http://www.openshot.org/>.
#
# OpenShot Library (libopenshot) is free software: you can redistribute it
# and/or modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# OpenShot Library (libopenshot) is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with OpenShot Library. If not, see <http://www.gnu.org/licenses/>.
################################################################################

cmake_minimum_required(VERSION 3.2...3.14 FATAL_ERROR)

message("\
-----------------------------------------------------------------
          Welcome to the OpenShot Build System!

CMake will now check libopenshot's build dependencies and inform
you of any missing files or other issues.

For more information, please visit <http://www.openshot.org/>.
-----------------------------------------------------------------")

################ ADD CMAKE MODULES ##################
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules")

################ PROJECT VERSION ####################
set(PROJECT_VERSION_FULL "0.2.5-dev2")
set(PROJECT_SO_VERSION 19)

# Remove the dash and anything following, to get the #.#.# version for project()
STRING(REGEX REPLACE "\-.*$" "" VERSION_NUM "${PROJECT_VERSION_FULL}")

################### SETUP PROJECT ###################
# This will define the following variables
# PROJECT_NAME
# PROJECT_VERSION, libopenshot_VERSION
# PROJECT_VERSION_MAJOR, libopenshot_VERSION_MAJOR
# PROJECT_VERSION_MINOR, libopenshot_VERSION_MINOR
# PROJECT_VERSION_PATCH, libopenshot_VERSION_PATCH
PROJECT(libopenshot LANGUAGES C CXX VERSION ${VERSION_NUM})

message("
Generating build files for OpenShot with CMake ${CMAKE_VERSION}
  Building ${PROJECT_NAME} (version ${PROJECT_VERSION})
  SO/API/ABI Version: ${PROJECT_SO_VERSION}
")

# Define install paths according to system conventions
# XXX: This must be AFTER THE PROJECT() COMMAND w/ languages enabled,
#      in order to properly configure CMAKE_INSTALL_LIBDIR path
include(GNUInstallDirs)

# Collect and display summary of options/dependencies
include(FeatureSummary)
include(CMakeDependentOption)

################ OPTIONS ##################
# Optional build settings for libopenshot
option(USE_SYSTEM_JSONCPP "Use system installed JsonCpp, if found" ON)
option(USE_VENDORED_CPPZMQ "Work around a missing zmq.hpp header" OFF)
option(DISABLE_BUNDLED_JSONCPP "Don't fall back to bundled JsonCpp" OFF)
option(ENABLE_MAGICK "Use ImageMagick, if available" ON)
option(APPIMAGE_BUILD "Build to install in an AppImage (Linux only)" OFF)
option(COMBINED_BUILD "Include audio library in build" OFF)
option(PACKAGED_BUILD "Bundle libraries into the generated Python package" OFF)

option(ENABLE_IWYU "Enable 'Include What You Use' scanner (CMake 3.3+)" OFF)
option(ENABLE_TESTS "Build unit tests (requires UnitTest++)" ON)
option(ENABLE_COVERAGE "Scan test coverage using gcov and report" OFF)

option(ENABLE_DOCS "Build API documentation (requires Doxygen)" ON)
# Only present configuration for docs build if enabled
cmake_dependent_option(
  LIB_DOCS_AUTO_BUILD
  "Automatically generate documentation"
  OFF "ENABLE_DOCS" OFF)  # Default OFF if not disabled
cmake_dependent_option(
  LIB_DOCS_AUTO_INSTALL
  "Include documentation in the default install"
  ON "ENABLE_DOCS" OFF)  # Default ON if not disabled

# Legacy commandline override
if (DISABLE_TESTS)
  set(ENABLE_TESTS OFF)
endif()

if(DEFINED ENABLE_TESTS)
  set(ENABLE_TESTS ${ENABLE_TESTS} CACHE BOOL "Build unit tests (requires UnitTest++)" FORCE)
endif()

###
### Install destinations
###

#if(APPLE)
#set(OPENSHOT_INCLUDE_DIRECTORY
#  "${CMAKE_INSTALL_LIBDIR}"
#  CACHE BOOL "Header install prefix (same as framework prefix)"
#)
#else()
set(OPENSHOT_INCLUDE_DIRECTORY
  "${CMAKE_INSTALL_INCLUDEDIR}/openshot"
  CACHE BOOL "Header install destination (relative to <INSTALL_PREFIX>)"
)
add_feature_info("Header install path" TRUE
  "Installing headers to <PREFIX>/${OPENSHOT_INCLUDE_DIRECTORY}")
#endif()

if(PACKAGED_BUILD)
  set(PYTHON_MODULE_PATH "${CMAKE_INSTALL_PREFIX}/python/libopenshot"
    CACHE PATH "Install location for packaged Python modules" FORCE)
  set(OPENSHOT_LIBDIR "${PYTHON_MODULE_PATH}"
    CACHE PATH "Shared library destination path" FORCE)
  endif()
  add_feature_info("Packaged libraries" TRUE
    "Installing shared libraries into Python package dir")
else()
  set(OPENSHOT_LIBDIR "${CMAKE_INSTALL_LIBDIR}"
    CACHE PATH "Shared library destination path")
endif()

if(WIN32 AND PACKAGED_BUILD)
  set(OPENSHOT_RUNTIME_DIR "${OPENSHOT_LIBDIR}"
    CACHE PATH "Runtime destination path" FORCE)
else()
  set(OPENSHOT_RUNTIME_DIR "${CMAKE_INSTALL_BINDIR}"
    CACHE PATH "Runtime destination path" FORCE)
endif()

#### Work around a GCC < 9 bug with handling of _Pragma() in macros
#### See https://gcc.gnu.org/bugzilla/show_bug.cgi?id=55578
if ((${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU") AND
    (${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS "9.0.0"))
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -no-integrated-cpp")
endif()

############## Code Coverage #########################
if (ENABLE_COVERAGE AND NOT ENABLE_TESTS)
  message(WARNING "ENABLE_COVERAGE requires unit tests, forcing ENABLE_TESTS")
  set(ENABLE_TESTS ON CACHE BOOL "Don't build unit tests" FORCE)
endif()

if (ENABLE_COVERAGE)
  if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
    message(STATUS "Coverage enabled, setting build type to Debug")
  endif()
  include(CodeCoverage)
  append_coverage_compiler_flags()
endif()
add_feature_info("Coverage" ENABLE_COVERAGE "analyze test coverage and generate report")

# Make sure we've picked some build type, default to release
if(NOT DEFINED CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "")
  set(CMAKE_BUILD_TYPE "Release")
endif()

###
### Process subdirectories
###
if(COMBINED_BUILD)
  add_subdirectory(extern/libopenshot-audio)
endif()
add_subdirectory(src)
add_subdirectory(examples)
add_subdirectory(bindings)

###
### Configure Version.h header
###
# (Note: This comes after the subdirectories, because it needs variables
#        set during the dependency discovery in src/CMakeLists.txt)
configure_file(src/OpenShotVersion.h.in src/OpenShotVersion.h @ONLY)
# We'll want that installed later
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/src/OpenShotVersion.h
        DESTINATION ${OPENSHOT_INCLUDE_DIRECTORY})


################### DOCUMENTATION ###################
# Find Doxygen (used for documentation)
set(LIB_DOCS_ENABLED FALSE) # Only set true if Doxygen is found and configured
if(NOT DEFINED ENABLE_LIB_DOCS)
  set(ENABLE_LIB_DOCS ${ENABLE_DOCS})
endif()
if (ENABLE_LIB_DOCS AND CMAKE_VERSION VERSION_GREATER 3.11)
  find_package(Doxygen)
  if(Doxygen_FOUND)
  	message(STATUS "Doxygen found, enabling ${PROJECT_NAME} documentation target")
    set(DOXYGEN_QUIET YES)
    set(DOXYGEN_PROJECT_NAME "OpenShot Library | libopenshot")
    set(DOXYGEN_PROJECT_NUMBER ${PROJECT_VERSION})
    set(DOXYGEN_STRIP_FROM_PATH "${PROJECT_SOURCE_DIR}/src")
    set(DOXYGEN_STRIP_FROM_INC_PATH "${PROJECT_SOURCE_DIR}/src")
    set(DOXYGEN_INCLUDE_FILE_PATTERNS "*.h")
    set(DOXYGEN_EXCLUDE
      ${PROJECT_SOURCE_DIR}/src/OpenShot.h
      ${PROJECT_SOURCE_DIR}/src/Effects.h
    )
    set(DOXYGEN_PREDEFINED USE_BLACKMAGIC USE_IMAGEMAGICK)
    set(DOXYGEN_IMAGE_PATH ${PROJECT_SOURCE_DIR})
    set(DOXYGEN_OUTPUT_DIRECTORY "docs")

    set(DOXYGEN_EXTRACT_ALL YES)
    set(DOXYGEN_SORT_BRIEF_DOCS YES)
    set(DOXYGEN_RECURSIVE YES)
    set(DOXYGEN_SOURCE_BROWSER YES)
    set(DOXYGEN_REFERENCED_BY_RELATION YES)

    set(DOXYGEN_HTML_OUTPUT "html")
    set(DOXYGEN_HTML_DYNAMIC_SECTIONS NO)

    set(DOXYGEN_DOT_IMAGE_FORMAT svg)
    set(DOXYGEN_INTERACTIVE_SVG YES)
    set(DOXYGEN_DOT_TRANSPARENT YES)

    doxygen_add_docs(${PROJECT_NAME}-doc
      ${PROJECT_SOURCE_DIR}/src
      ${PROJECT_SOURCE_DIR}/doc
      ${PROJECT_BINARY_DIR}/src/OpenShotVersion.h
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      COMMENT "Generate ${PROJECT_NAME} documentation"
    )
  endif()
endif()
if (TARGET ${PROJECT_NAME}-doc)
	set(LIB_DOCS_ENABLED TRUE)

  # Install docs, if the user builds them with `make doc`
  install(CODE "MESSAGE(\"Checking for documentation files to install...\")")
    install(CODE "MESSAGE(\"(Compile with 'make doc' command, requires Doxygen)\")")

    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doc/html/
          DESTINATION ${CMAKE_INSTALL_DOCDIR}/API
          MESSAGE_NEVER # Don't spew about file copies
          OPTIONAL )    # No error if the docs aren't found

  if(NOT TARGET doc)
    add_custom_target(doc)
  endif()
  if(TARGET doc)
    add_dependencies(doc ${PROJECT_NAME}-doc)
  endif()
endif()
add_feature_info("${PROJECT_NAME} docs" LIB_DOCS_ENABLED "Build ${PROJECT_NAME} API documentation")

if(NOT TARGET ${PROJECT_NAME}-doc)
  # Dummy target to prevent failed build runs
  add_custom_target(${PROJECT_NAME}-doc)
endif()

############# PROCESS tests/ DIRECTORY ##############
if(ENABLE_TESTS)
  set(TESTS_ENABLED TRUE) # May be overridden by tests/CMakeLists.txt
  add_subdirectory(tests)
endif()
add_feature_info("Unit tests" TESTS_ENABLED "Compile unit tests for library functions")

############## COVERAGE REPORTING #################
if (ENABLE_COVERAGE)
  setup_target_for_coverage_lcov(
    NAME coverage
    LCOV_ARGS "--no-external"
    EXECUTABLE openshot-test
    DEPENDENCIES OpenShot::Lib openshot-test
    EXCLUDE
      "bindings/*"
      "examples/*"
      "${CMAKE_CURRENT_BINARY_DIR}/bindings/*"
      "${CMAKE_CURRENT_BINARY_DIR}/src/*_autogen/*"
  )
  if(NOT TARGET os_test)
    add_custom_target(os_test)
    add_dependencies(os_test coverage)
  endif()
endif()

# Also hook up 'test' as an alias for the 'os_test' target, if possible
# This requires CMake 3.11+, where the CMP0037 policy
# configured to 'NEW' mode will not reserve target names
# unless the corresponding feature is actually used
if (POLICY CMP0037)
	cmake_policy(SET CMP0037 NEW)
endif()
if(TARGET os_test)
  if (CMAKE_VERSION VERSION_GREATER 3.11)
    message(STATUS "Cmake 3.11+ detected, enabling 'test' target")
    add_custom_target(test)
    add_dependencies(test os_test)
    set(TEST_TARGET_NAME "test")
  else()
    set(TEST_TARGET_NAME "os_test")
  endif()
  add_feature_info("Testrunner" ENABLE_TESTS "Run unit tests with 'make ${TEST_TARGET_NAME}'")
else()
  # Dummy target to prevent failed build runs
  add_custom_target(os_test)
endif()

###
### PRINT FEATURE SUMMARY
###
feature_summary(WHAT ALL
  INCLUDE_QUIET_PACKAGES
  FATAL_ON_MISSING_REQUIRED_PACKAGES
  DESCRIPTION "${PROJECT_NAME} build configuration:")
