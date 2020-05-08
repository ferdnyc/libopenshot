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

include(FeatureSummary)
include(GNUInstallDirs)

### Enable some legacy SWIG behaviors, in newer CMAKEs
if (POLICY CMP0078)
	cmake_policy(SET CMP0078 NEW)
endif()
if (POLICY CMP0086)
	cmake_policy(SET CMP0086 NEW)
endif()
if (POLICY CMP0070)
  cmake_policy(SET CMP0070 OLD)
endif()

if (NOT DEFINED ENABLE_PYTHON)
    set(ENABLE_PYTHON 1)
endif()

if (NOT DEFINED ENABLE_RUBY)
    set(ENABLE_RUBY 1)
endif()

if (NOT ENABLE_PYTHON AND NOT ENABLE_RUBY)
  return()
endif()

find_package(SWIG 3.0 REQUIRED)
include(${SWIG_USE_FILE})

include_directories(${PROJECT_SOURCE_DIR}/src ${PROJECT_BINARY_DIR}/src)

### Enable C++ support in SWIG
set_property(SOURCE openshot.i PROPERTY CPLUSPLUS ON)

#separate_arguments(sw_flags UNIX_COMMAND ${SWIG_CXX_FLAGS})
#set_property(SOURCE openshot.i PROPERTY GENERATED_COMPILE_OPTIONS ${sw_flags})

## Take include dirs from target, automatically if possible
if(CMAKE_VERSION VERSION_GREATER 3.13)
	set_property(SOURCE openshot.i PROPERTY
    USE_TARGET_INCLUDE_DIRECTORIES True
  )
else()
	set_property(SOURCE openshot.i PROPERTY
    GENERATED_INCLUDE_DIRECTORIES
    $<TARGET_PROPERTY:openshot_obj,INCLUDE_DIRECTORIES>
  )
  set_property(SOURCE openshot.i property
    GENERATED_COMPILE_OPTIONS
    $<TARGET_PROPERTY:openshot_obj,COMPILE_OPTIONS>
  )
  set_property(SOURCE openshot.i property
    GENERATED_COMPILE_DEFINITIONS
    $<TARGET_PROPERTY:openshot_obj,COMPILE_DEFINITIONS>
  )
endif()

############### Discover each enabled language ################
if (ENABLE_PYTHON AND NOT PYTHON_CREATE_PACKAGE)
  include(SWIGPython)

  ### Set output name of target
  set_target_properties(${SWIG_PYTHON_TARGET} PROPERTIES
    PREFIX "_"
  )

  target_link_libraries(${SWIG_PYTHON_TARGET} PUBLIC ${PYTHON_LIBRARIES})

  if(BUILD_INSTALLABLE)
    target_link_libraries(${SWIG_PYTHON_TARGET} PUBLIC openshot)
  else()
    target_link_libraries(${SWIG_PYTHON_TARGET} PUBLIC openshot_obj)
  endif()

  if(ENABLE_AUDIO_LIB)
    target_link_libraries(${SWIG_PYTHON_TARGET} PUBLIC openshot-audio)
  endif()

  install(TARGETS ${SWIG_PYTHON_TARGET}
    DESTINATION python/
  )

endif() # ENABLE_PYTHON

########## Ruby ##########

if (ENABLE_RUBY)
  find_package(Ruby)
endif()

if (ENABLE_RUBY AND RUBY_FOUND)
	### Include the Ruby header files
	include_directories(${RUBY_INCLUDE_DIRS})
  include_directories($<TARGET_PROPERTY:openshot_obj,INCLUDE_DIRECTORIES>)

	### Add the SWIG interface file (which defines all the SWIG methods)
	if (CMAKE_VERSION VERSION_LESS 3.8.0)
		swig_add_module(rbopenshot ruby openshot.i)
	else()
		swig_add_library(rbopenshot
			LANGUAGE ruby
			SOURCES openshot.i
		)
	endif()

	### Set name of target (with no prefix, since Ruby does not like that)
	SET_TARGET_PROPERTIES(${SWIG_MODULE_rbopenshot_REAL_NAME} PROPERTIES
    PREFIX ""
		OUTPUT_NAME "openshot"
  )

  ### Link the new Ruby wrapper library with libopenshot
	target_link_libraries(${SWIG_MODULE_rbopenshot_REAL_NAME} PUBLIC ${RUBY_LIBRARY})

  if(BUILD_INSTALLABLE)
    target_link_libraries(${SWIG_MODULE_rbopenshot_REAL_NAME} PUBLIC openshot)
  else()
    target_link_libraries(${SWIG_MODULE_rbopenshot_REAL_NAME} PUBLIC openshot_obj)
  endif()


  if(ENABLE_AUDIO_LIB)
    target_link_libraries(${SWIG_MODULE_rbopenshot_REAL_NAME} PUBLIC openshot-audio)
  endif()

  ###
  ### Ruby install path
  ###
  if (NOT DEFINED RUBY_MODULE_PATH AND DEFINED ENV{RUBY_MODULE_PATH})
    set(RUBY_MODULE_PATH $ENV{RUBY_MODULE_PATH})
  endif()

  if (NOT DEFINED RUBY_MODULE_PATH)
    if (WIN32 OR APPLE)
      set (RUBY_MODULE_PATH "ruby")
    endif()

    if (UNIX AND NOT APPLE)
      ### FIND THE RUBY INTERPRETER (AND THE LOAD_PATH FOLDER)
      execute_process(COMMAND ${RUBY_EXECUTABLE} -r rbconfig
        -e "dir = RbConfig::CONFIG['vendorarchdir']"
        -e "dir.start_with?(RbConfig::CONFIG['prefix']) && dir.sub!(RbConfig::CONFIG['prefix']+'/', '')"
        -e "p dir"
        OUTPUT_VARIABLE RUBY_MODULE_PATH
        OUTPUT_STRIP_TRAILING_WHITESPACE )
      # Ruby quotes its output strings
      string(REPLACE "\"" "" RUBY_MODULE_PATH "${RUBY_MODULE_PATH}")
    endif()
  endif()

  message(STATUS "RUBY_MODULE_PATH: ${CMAKE_INSTALL_PREFIX}/${RUBY_MODULE_PATH}")
  # Install Ruby bindings
  install(TARGETS ${SWIG_MODULE_rbopenshot_REAL_NAME}
    DESTINATION ${RUBY_MODULE_PATH} )

endif() # ENABLE_RUBY
