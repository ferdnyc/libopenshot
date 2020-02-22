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

### Suppress a ton of warnings in the generated SWIG C++ code
set(SWIG_CXX_FLAGS "-Wno-unused-variable -Wno-unused-function -Wno-deprecated-copy -Wno-class-memaccess -Wno-cast-function-type \
-Wno-unused-parameter -Wno-catch-value -Wno-sign-compare -Wno-ignored-qualifiers")

if (CMAKE_VERSION VERSION_LESS 3.13.0)
  include_directories(${PROJECT_SOURCE_DIR}/include ${PROJECT_BINARY_DIR}/include)
endif()

### Enable C++ support in SWIG
set_property(SOURCE openshot.i PROPERTY CPLUSPLUS ON)
#set_property(SOURCE python.i PROPERTY SWIG_MODULE_NAME "lib")

separate_arguments(sw_flags UNIX_COMMAND ${SWIG_CXX_FLAGS})
set_property(SOURCE openshot.i PROPERTY GENERATED_COMPILE_OPTIONS ${sw_flags})

### Take include dirs from target, automatically if possible
if (CMAKE_VERSION VERSION_GREATER 3.13)
	set_property(SOURCE openshot.i PROPERTY USE_TARGET_INCLUDE_DIRECTORIES True)
elseif (CMAKE_VERSION VERSION_GREATER 3.12)
	set_property(SOURCE openshot.i PROPERTY
		INCLUDE_DIRECTORIES $<TARGET_PROPERTY:openshot,INCLUDE_DIRECTORIES>)
endif ()

############### Discover each enabled language ################
if (ENABLE_PYTHON)
  find_package(PythonInterp 3)
  find_package(PythonLibs 3)
endif()

if (ENABLE_RUBY)
  find_package(Ruby)
endif()

########### Python ###########
if (ENABLE_PYTHON AND PYTHONLIBS_FOUND AND PYTHONINTERP_FOUND)
	include_directories(${PYTHON_INCLUDE_PATH})

	### Add the SWIG interface file (which defines all the SWIG methods)
	if (CMAKE_VERSION VERSION_LESS 3.8.0)
		set(CMAKE_SWIG_OUTDIR "${CMAKE_CURRENT_BINARY_DIR}/libopenshot")
		swig_add_module(pyopenshot python openshot.i)
	else()
		swig_add_library(pyopenshot
		  LANGUAGE python
		  SOURCES openshot.i
      OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/libopenshot"
      # OUTFILE_DIR "${CMAKE_CURRENT_BINARY_DIR}/libopenshot"
    )
	endif()

	### Set output name of target
	set_target_properties(${SWIG_MODULE_pyopenshot_REAL_NAME} PROPERTIES
    PREFIX "_"
    OUTPUT_NAME "openshot"
    OUTPUT_DIRECTORY "libopenshot/"
  )

  # Always
  set(_bundled_targets ${SWIG_MODULE_pyopenshot_REAL_NAME})

  if (BUILD_BUNDLED)
    # Build shared library for Python package
    add_library(py_pkg_lib SHARED)
    target_link_libraries(py_pkg_lib PUBLIC openshot_obj)

    set_target_properties(py_pkg_lib
      PROPERTIES
        PREFIX "_"
        LIBRARY_OUTPUT_NAME "pylibopenshot"
        OUTPUT_DIRECTORY "libopenshot/"
        NO_SONAME TRUE
    )

    if(CMAKE_VERSION VERSION_GREATER 3.14)
      foreach(_target ${SWIG_MODULE_pyopenshot_REAL_NAME} py_pkg_lib)
        set_target_properties(${_target}
          PROPERTIES
            BUILD_RPATH_USE_ORIGIN TRUE
        )
      endforeach()
    endif()
    # Also include openshot
    list(APPEND _bundled_targets py_pkg_lib)
  endif()

  # Fix RPATH on libs being bundled
  foreach(_b_t IN LISTS _bundled_targets)

      if (APPLE)
        set_property(TARGET ${_b_t}
          PROPERTY INSTALL_RPATH "@loader_path")
      elseif(UNIX)
        set_property(TARGET ${_b_t}
          PROPERTY INSTALL_RPATH "$ORIGIN")
      endif()
  endforeach()

  ### Link the new python wrapper library with the rest of libopenshot
  if(BUILD_BUNDLED)
    # Link our module with the bundled lib
    set(_module_linked py_pkg_lib)
  elseif(BUILD_INSTALLABLE)
    # Link to the installable shared library
    set(_module_linked openshot)
  else()
    # Link the library classes directly into the module
    set(_module_linked openshot_obj)
  endif()

	target_link_libraries(${SWIG_MODULE_pyopenshot_REAL_NAME} PUBLIC
    ${PYTHON_LIBRARIES}
    ${_module_linked}
  )

  if(PYTHON_BUILD_PACKAGE)
    # Special installation component PyPackage will "install"
    # the package components inside the build dir for packaging
    # by setup.py
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libopenshot/openshot.py
      COMPONENT PyPackage EXCLUDE_FROM_ALL
      DESTINATION python/libopenshot/
    )

    install(TARGETS pyopenshot
      COMPONENT PyPackage EXCLUDE_FROM_ALL
      DESTINATION python/libopenshot/
    )

    ### Create package __init__.py
    file(GENERATE
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/libopenshot/__init__.py"
  		INPUT "${CMAKE_CURRENT_SOURCE_DIR}/libopenshot_init.py.in")

    ### Create deprecation wrapper module
    file(GENERATE
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/openshot/__init__.py
  		INPUT ${CMAKE_CURRENT_SOURCE_DIR}/openshot_init.py.in)

    # if(BUILD_BUNDLED)
    #   install(TARGETS py_pkg_lib
    #     COMPONENT PyPackage EXCLUDE_FROM_ALL
    #     DESTINATION python/libopenshot
    #   )
    # endif()

    # Install the executable in the packaging dir and create a sentinel file
    # add_custom_command(OUTPUT ${PROJECT_BINARY_DIR}/python
    #   DEPENDS
    #     ${SWIG_MODULE_pyopenshot_REAL_NAME}
    #     cmake_install.cmake
    #   #COMMAND ${CMAKE_MAKE_PROGRAM} install PyPackage DESTDIR=${CMAKE_CURRENT_BINARY_DIR}/pypkg
    #   COMMAND ${CMAKE_COMMAND}
    #     -DCOMPONENT=PyPackage
    #     -DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}
    #     -P cmake_install.cmake
    #   COMMAND ${CMAKE_COMMAND} -E touch pkg_dir_updated
    #   VERBATIM
    #   BYPRODUCTS
    #     ${PROJECT_BINARY_DIR}/python/libopenshot/openshot.py
    #     ${PROJECT_BINARY_DIR}/python/libopenshot/_openshot.so
    # )
    #
    # # Make sure the pkg_dir flag is removed when pyopenshot is rebuilt
    # add_custom_command(TARGET ${SWIG_MODULE_pyopenshot_REAL_NAME}
    #   POST_BUILD
    #   COMMAND ${CMAKE_COMMAND} -E rm -r python
    #   WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    #   VERBATIM
    # )

  endif() # PYTHON_BUILD_PACKAGE

endif() # ENABLE_PYTHON

########## Ruby ##########
if (ENABLE_RUBY AND RUBY_FOUND)
	### Include the Ruby header files
	include_directories(${RUBY_INCLUDE_DIRS})

	### Add the SWIG interface file (which defines all the SWIG methods)
	if (CMAKE_VERSION VERSION_LESS 3.8.0)
		# set(CMAKE_SWIG_OUTDIR "${CMAKE_CURRENT_BINARY_DIR}")
		swig_add_module(rbopenshot ruby openshot.i)
	else()
		swig_add_library(rbopenshot
			LANGUAGE ruby
			SOURCES openshot.i
			# OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/ruby/openshot"
		  # OUTFILE_DIR "${CMAKE_CURRENT_BINARY_DIR}/ruby/openshot"
		)
	endif()

	### Set name of target (with no prefix, since Ruby does not like that)
	SET_TARGET_PROPERTIES(${SWIG_MODULE_rbopenshot_REAL_NAME} PROPERTIES
    PREFIX ""
		OUTPUT_NAME "openshot"
    # OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/ruby/openshot"
  )

	### Link the new Ruby wrapper library with libopenshot
	target_link_libraries(${SWIG_MODULE_rbopenshot_REAL_NAME}
    PUBLIC
      ${RUBY_LIBRARY}
      openshot
  )

  ###
  ### Ruby install path
  ###
  if (NOT DEFINED RUBY_MODULE_PATH AND DEFINED $ENV{RUBY_MODULE_PATH})
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
