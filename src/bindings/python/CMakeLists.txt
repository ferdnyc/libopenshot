####################### CMakeLists.txt (libopenshot) #########################
# @brief CMake build file for libopenshot (used to generate Python SWIG bindings)
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


############### SWIG PYTHON BINDINGS ################
find_package(SWIG 3.0 REQUIRED)
include(${SWIG_USE_FILE})

### Enable some legacy SWIG behaviors, in newer CMAKEs
if (POLICY CMP0078)
  cmake_policy(SET CMP0078 OLD)
endif()
if (POLICY CMP0086)
  cmake_policy(SET CMP0086 OLD)
endif()
# Find Python components by LOCATION (path), not by VERSION
if(POLICY CMP0094)
  cmake_policy(SET CMP0094 NEW)
endif()

if(CMAKE_VERSION VERSION_GREATER 3.12)
  find_package(Python3 COMPONENTS Interpreter Development)
  if(NOT Python3_FOUND)
    return()
  endif()
  set(PYTHON_EXECUTABLE ${Python3_EXECUTABLE})
  set(PYTHON_TARGET Python3::Python)
else()
  find_package(PythonInterp 3)
  find_package(PythonLibs 3)
  if (NOT PYTHONLIBS_FOUND OR NOT PYTHONINTERP_FOUND)
    return()
  endif()
  if(NOT TARGET Python_LIB)
    # Older CMake versions (< 3.9) don't create find targets.
    add_library(Python_LIB INTERFACE)
    target_include_directories(Python_LIB INTERFACE
    ${PYTHON_INCLUDE_DIRS})
    target_link_libraries(Python_LIB INTERFACE
    ${PYTHON_LIBRARIES})
  endif()
  set(PYTHON_TARGET Python_LIB)
  ## Include headers -- won't be pulled from targets
  include_directories(
    "${PROJECT_SOURCE_DIR}/include"
    "${PROJECT_BINARY_DIR}/include")
endif()

### Enable C++ support in SWIG
set_property(SOURCE openshot.i PROPERTY CPLUSPLUS ON)
set_property(SOURCE openshot.i PROPERTY SWIG_MODULE_NAME openshot)

### Suppress a ton of warnings in the generated SWIG C++ code
set(SWIG_CXX_FLAGS "-Wno-unused-variable -Wno-unused-function \
  -Wno-deprecated-copy -Wno-class-memaccess -Wno-cast-function-type \
  -Wno-unused-parameter -Wno-catch-value -Wno-sign-compare -Wno-ignored-qualifiers")
separate_arguments(sw_flags UNIX_COMMAND ${SWIG_CXX_FLAGS})
set_property(SOURCE openshot.i PROPERTY GENERATED_COMPILE_OPTIONS ${sw_flags})

### Take include dirs from target, automatically if possible
if (CMAKE_VERSION VERSION_GREATER 3.13)
  set_property(SOURCE openshot.i PROPERTY USE_TARGET_INCLUDE_DIRECTORIES True)
elseif (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(SOURCE openshot.i APPEND PROPERTY
    INCLUDE_DIRECTORIES $<TARGET_PROPERTY:openshot,INCLUDE_DIRECTORIES>)
endif ()

### Add the SWIG interface file (which defines all the SWIG methods)
if (CMAKE_VERSION VERSION_LESS 3.8.0)
  swig_add_module(pyopenshot python openshot.i)
else()
  swig_add_library(pyopenshot LANGUAGE python SOURCES openshot.i)
endif()

### Set output name of target
set_target_properties(${SWIG_MODULE_pyopenshot_REAL_NAME} PROPERTIES
  PREFIX "_" OUTPUT_NAME "openshot")

### Link the new python wrapper library with libopenshot
target_link_libraries(${SWIG_MODULE_pyopenshot_REAL_NAME} PUBLIC openshot)
target_link_libraries(${SWIG_MODULE_pyopenshot_REAL_NAME} PUBLIC ${PYTHON_TARGET})

######### INSTALL PATH ########
if (NOT DEFINED PYTHON_INSTALL_PATH AND DEFINED $ENV{PYTHON_INSTALL_PATH})
  set(PYTHON_INSTALL_PATH $ENV{PYTHON_INSTALL_PATH})
endif()
if (NOT DEFINED PYTHON_INSTALL_PATH AND DEFINED $ENV{PYTHON_MODULE_PATH})
  set(PYTHON_INSTALL_PATH $ENV{PYTHON_MODULE_PATH})
endif()

if (NOT DEFINED PYTHON_INSTALL_PATH)
  if (WIN32 OR APPLE)
    set (PYTHON_INSTALL_PATH "python")
  endif()

  if (UNIX AND NOT APPLE)
    ### Check if the following Debian-friendly python module path exists
    set(PYTHON_INSTALL_PATH
      "lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/dist-packages")

    if (NOT EXISTS "${CMAKE_INSTALL_PREFIX}/${PYTHON_INSTALL_PATH}")
      ### Calculate the python module path (using distutils)
      execute_process ( COMMAND ${PYTHON_EXECUTABLE} -c "\
from distutils.sysconfig import get_python_lib; \
print( get_python_lib( plat_specific=True, prefix='' ) )"
        OUTPUT_VARIABLE PYTHON_INSTALL_PATH
        OUTPUT_STRIP_TRAILING_WHITESPACE )
    endif()
  endif()
endif()

message(STATUS "PYTHON_INSTALL_PATH: ${CMAKE_INSTALL_PREFIX}/${PYTHON_INSTALL_PATH}")

############### INSTALL HEADERS & LIBRARY ################
### Install Python bindings
install(TARGETS ${SWIG_MODULE_pyopenshot_REAL_NAME}
  DESTINATION ${PYTHON_INSTALL_PATH} )
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/openshot.py
  DESTINATION ${PYTHON_INSTALL_PATH} )
