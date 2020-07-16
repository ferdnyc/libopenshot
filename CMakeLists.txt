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

### ADD CMAKE MODULES
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

### Note: A file cmake/UserDefaults.cmake in the project repository
### will by default be read to pre-set options for each build. The
### contents are processed before the initial project() command.
###
### It is safe to use this file to store your local build settings.
### It is listed in the project .gitignore and cannot be committed.
###
### To temporarily override the automatic loading of UserDefaults.cmake
### in the current build, set IGNORE_DEFAULTS on the cmake command line:
###
###   cmake -DIGNORE_DEFAULTS:BOOL=TRUE -B build -S .

### Load user/project defaults if supported, unless overridden
option(IGNORE_DEFAULTS OFF "Don't import local settings from UserDefaults.cmake (CMake 3.15+ only)")
if (CMAKE_VERSION VERSION_GREATER 3.15 AND NOT IGNORE_DEFAULTS)
  set(_defaults_file "${CMAKE_SOURCE_DIR}/cmake/UserDefaults.cmake")
  if (EXISTS ${_defaults_file})
    set(CMAKE_PROJECT_INCLUDE_BEFORE "${_defaults_file}")
  endif()
endif()

################ PROJECT VERSION ####################
set(PROJECT_VERSION_FULL "0.2.5-dev2" CACHE STRING "Extended version string" FORCE)
set(PROJECT_SO_VERSION 19 CACHE STRING "library API version" FORCE)

### METADATA
set(PROJECT_AUTHOR "Jonathan Thomas and contributors")
set(PROJECT_AUTHOR_EMAIL "jonathan@openshot.org")
set(PROJECT_MAINTAINER "Jonathan Thomas")
set(PROJECT_MAINTAINER_EMAIL "jonathan@openshot.org")
set(PROJECT_URL "https://github.com/OpenShot/libopenshot/")
set(PROJECT_SUMMARY "C++ audio-video processing library that enables high-quality video editing.")
set(PROJECT_DESCRIPTION [=[
OpenShot Library (libopenshot) is a free, open-source project that enables high-quality video editing.
]=])

### METADATA
set(PROJECT_AUTHOR "Jonathan Thomas and contributors" CACHE STRING "Project metadata")
set(PROJECT_AUTHOR_EMAIL "jonathan@openshot.org" CACHE STRING "Project metadata")
set(PROJECT_MAINTAINER "Jonathan Thomas" CACHE STRING "Project metadata")
set(PROJECT_MAINTAINER_EMAIL "jonathan@openshot.org" CACHE STRING "Project metadata")
set(PROJECT_URL "https://github.com/OpenShot/libopenshot/" CACHE STRING "Project metadata")

# Remove the dash and anything following, to get the #.#.# version for project()
STRING(REGEX REPLACE "\-.*$" "" VERSION_NUM "${PROJECT_VERSION_FULL}")

###
### SETUP PROJECT
###
# This will define the following variables
# PROJECT_NAME
# PROJECT_VERSION, libopenshot_VERSION
# PROJECT_VERSION_MAJOR, libopenshot_VERSION_MAJOR
# PROJECT_VERSION_MINOR, libopenshot_VERSION_MINOR
# PROJECT_VERSION_PATCH, libopenshot_VERSION_PATCH
PROJECT(libopenshot LANGUAGES C CXX VERSION ${VERSION_NUM})

message("
Generating build files for OpenShot with CMake ${CMAKE_VERSION}
  Building ${PROJECT_NAME} version ${PROJECT_VERSION_FULL}
  SO/API/ABI Version: ${PROJECT_SO_VERSION}
")

# Define install paths according to system conventions
# XXX: This must be AFTER THE PROJECT() COMMAND w/ languages enabled,
#      in order to properly configure CMAKE_INSTALL_LIBDIR path
include(GNUInstallDirs)

# Collect and display summary of options/dependencies
include(FeatureSummary)

# Set up option() dependencies
include(CMakeDependentOption)

###
### OPTIONS
###
# Configurable build settings for libopenshot

# What to build
option(ENABLE_INSTALLABLE "Build an installable shared library" ON)
option(ENABLE_BUNDLED "Build lib for direct inclusion with bindings" OFF)
option(ENABLE_AUDIO_LIB "Build audio lib from submodule" OFF)
option(ENABLE_PYTHON "Generate Python bindings using SWIG" ON)
option(ENABLE_RUBY "Generate Ruby bindings using SWIG" ON)

# What to include
option(USE_SYSTEM_JSONCPP "Use system installed JsonCpp, if found" ON)
option(DISABLE_BUNDLED_JSONCPP "Don't fall back to bundled JsonCpp" OFF)

# What to do while building it
option(ENABLE_IWYU "Enable 'Include What You Use' scanner (CMake 3.3+)" OFF)
option(ENABLE_TESTS "Build unit tests (requires UnitTest++)" ON)
option(ENABLE_DOCS "Build API documentation (requires Doxygen)" ON)
option(APPIMAGE_BUILD "Build to install in an AppImage (Linux only)" OFF)

###
### Create dependent options and process conditionals
###

# Python package requires Python (duh)
cmake_dependent_option(PYTHON_CREATE_PACKAGE
  "Package bindings using setuptools"
  ON "ENABLE_PYTHON" # default on if enabled
  OFF
)
# Bundling option (EXPERIMENTAL) requires Python bindings and packaging enabled
cmake_dependent_option(PYTHON_BUNDLE_LIBS
  "Incorporate libopenshot directly into Python package"
  # default OFF even if conditions TRUE
  OFF "ENABLE_PYTHON;PYTHON_CREATE_PACKAGE"
  OFF  # else forced OFF unconditionally (disabled)
)
# If bundling enabled, default to including libopenshot-audio
cmake_dependent_option(PYTHON_BUNDLE_AUDIO_LIB
  "Integrate audio lib into bundled build"
  ON "PYTHON_BUNDLE_LIBS"
  OFF
)
if (PYTHON_BUNDLE_LIBS)
  set(ENABLE_BUNDLED ON)
endif()
if (PYTHON_BUNDLE_AUDIO_LIB)
  set(ENABLE_AUDIO_LIB ON)
endif()

# Legacy commandline override
if (DISABLE_TESTS)
  if(ENABLE_COVERAGE)
    message(WARNING "ENABLE_COVERAGE requires tests, overriding DISABLE_TESTS")
    set(ENABLE_TESTS ON)
  else()
    set(ENABLE_TESTS OFF)
  endif()
endif()

if(DEFINED ENABLE_TESTS)
  set(ENABLE_TESTS ${ENABLE_TESTS} CACHE BOOL "Build unit tests (requires UnitTest++)" FORCE)
endif()

if(ENABLE_PYTHON)
  set(PYTHON_ENABLED ON)
endif()
if(ENABLE_RUBY)
  set(RUBY_ENABLED ON)
endif()

# Work around a GCC < 9 bug with handling of _Pragma() in macros
# See https://gcc.gnu.org/bugzilla/show_bug.cgi?id=55578
if ((${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU") AND
    (${CMAKE_CXX_COMPILER_VERSION} VERSION_LESS "9.0.0"))
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -no-integrated-cpp")
endif()

#### Enable C++11 (for std::shared_ptr support)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

############## Code Coverage #########################
if (DISABLE_TESTS AND ENABLE_COVERAGE)
  message(WARNING "ENABLE_COVERAGE requires tests, overriding DISABLE_TESTS")
  set(DISABLE_TESTS OFF CACHE BOOL "Don't build unit tests" FORCE)
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

# Juce requires either DEBUG or NDEBUG to be defined on MacOS.
# -DNDEBUG is set by cmake for all release configs, so add
# -DDEBUG for debug builds. We'll do this for all OSes, even
# though only MacOS requires it.
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG")
# Make sure we've picked some build type, default to debug
if(NOT DEFINED CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "")
  set(CMAKE_BUILD_TYPE "Debug")
endif()

###
### SUBDIRECTORIES
###
if (ENABLE_AUDIO_LIB)
  add_subdirectory(libopenshot-audio)
else()
  find_package(OpenShotAudio 0.2.0 REQUIRED)
endif()

add_subdirectory(src)
add_subdirectory(examples)

# Generate SWIG bindings
if(RUBY_ENABLED OR PYTHON_ENABLED)
  add_subdirectory(bindings)
endif()

################### DOCUMENTATION ###################
if(PYTHON_CREATE_PACKAGE)
  add_subdirectory(packaging/python)
endif()

###
### DOCUMENTATION
###
# Find Doxygen (used for documentation)
set(DOCS_ENABLED FALSE) # Only set true if Doxygen is found and configured
if (ENABLE_DOCS)
  set(DOXYGEN_TARGET_NAME "doxygen-libopenshot")
  set(DOXYGEN_DOC_TARGET_NAME "libopenshot-docs")
  include(UseDoxygen)

  # Doxygen was found
  if (TARGET ${DOXYGEN_DOC_TARGET_NAME})
  	message(STATUS "Doxygen found, documentation target enabled")
  	set(DOCS_ENABLED TRUE)

    # Install docs, if the user builds them with `make doc`
    install(CODE "MESSAGE(\"Checking for documentation files to install...\")")
    install(CODE "MESSAGE(\"(Compile with 'make ${DOXYGEN_DOC_TARGET_NAME}' command, requires Doxygen)\")")

    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/doc/html/
            DESTINATION ${CMAKE_INSTALL_DOCDIR}/API
            MESSAGE_NEVER # Don't spew about file copies
            OPTIONAL )    # No error if the docs aren't found
  endif()
endif()
add_feature_info("Documentation" DOCS_ENABLED "Build API documentation with 'make ${DOXYGEN_DOC_TARGET_NAME}'")

###
### Unit Tests
###
if(ENABLE_TESTS)
  set(TESTS_ENABLED TRUE) # May be overridden by tests/CMakeLists.txt
  add_subdirectory(tests)
endif()
add_feature_info("Unit tests" TESTS_ENABLED "Compile unit tests for library functions")

###
### Coverage reporting
###
if (ENABLE_COVERAGE)
  setup_target_for_coverage_lcov(
    NAME coverage
    LCOV_ARGS "--no-external"
    EXECUTABLE openshot-test
    DEPENDENCIES openshot-test)
    message("Generate coverage report with 'make coverage'")
  add_feature_info("Coverage unit" ENABLE_COVERAGE "generate report with 'make coverage'")
endif()

### Display feature summary
feature_summary(WHAT ALL
    INCLUDE_QUIET_PACKAGES
    FATAL_ON_MISSING_REQUIRED_PACKAGES
    DESCRIPTION "Displaying feature summary\n\nBuild configuration:")

###
### CPack packaging metadata
###
set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION_FULL})
set(CPACK_PACKAGE_HOMEPAGE_URL ${PROJECT_URL})
if(MINGW)
	set(CPACK_GENERATOR "NuGet")
  set(CPACK_PACKAGE_DIRECTORY ${CMAKE_INSTALL_PREFIX})
endif()
if(UNIX AND NOT APPLE)
	set(CPACK_GENERATOR "DEB")
  set(CPACK_DEBIAN_PACKAGE_MAINTAINER ${PROJECT_MAINTAINER}) #required
endif()
#if(UNIX AND APPLE)
#	set(CPACK_GENERATOR "DragNDrop")
#endif()

include(CPack)
