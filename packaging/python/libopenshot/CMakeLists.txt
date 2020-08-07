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

# This will set up the module target, and export its name
# into our context as SWIG_PYTHON_TARGET
include_directories($<TARGET_PROPERTY:openshot_obj,INCLUDE_DIRECTORIES>)
include(SWIGPython)

if(PYTHON_BUNDLE_LIBS)
  # Build shared libopenshot for Python package
  add_library(py_pkg_openshot SHARED $<TARGET_OBJECTS:openshot_obj>)
  target_link_libraries(py_pkg_openshot PUBLIC openshot_obj)

  set_target_properties(py_pkg_openshot
    PROPERTIES
      PREFIX "_"
      LIBRARY_OUTPUT_NAME "pylibopenshot"
      NO_SONAME TRUE
  )

  set(_local_targets py_pkg_openshot)

  if(ENABLE_AUDIO_LIB AND PYTHON_BUNDLE_AUDIO_LIB)
    add_library(py_pkg_openshot_audio SHARED
      $<TARGET_OBJECTS:openshot-audio>)
    target_link_libraries(py_pkg_openshot_audio PUBLIC openshot-audio)

    set_target_properties(py_pkg_openshot_audio
      PROPERTIES
        PREFIX "_"
        LIBRARY_OUTPUT_NAME "pylibopenshot-audio"
        NO_SONAME TRUE
    )

    list(APPEND _local_targets py_pkg_openshot_audio)
  endif()

  if(ENABLE_AUDIO_LIB AND NOT PYTHON_BUNDLE_AUDIO_LIB)
    list(APPEND _local_targets openshot-audio)
  endif()

  # Set up the components' build RPATH
  foreach(_target ${SWIG_PYTHON_TARGET} ${_local_targets})
    if(CMAKE_VERSION VERSION_GREATER 3.14)
      set_target_properties(${_target}
        PROPERTIES
          BUILD_RPATH_USE_ORIGIN TRUE
      )
    else()
      if(APPLE)
        set_property(TARGET ${_b_t}
          PROPERTY BUILD_RPATH "@rpath")
      elseif(UNIX)
        set_property(TARGET ${_b_t}
          PROPERTY BUILD_RPATH "$ORIGIN")
      endif()
    endif()
  endforeach()

  set(_target_link_libraries ${_local_targets})
else()
  set(_target_link_libraries openshot)

  if(ENABLE_AUDIO_LIB)
    list(APPEND _target_link_libraries openshot-audio)
  endif()
endif()

target_link_libraries(${SWIG_PYTHON_TARGET} PUBLIC
  ${_target_link_libraries}
)


### Create package __init__.py
file(GENERATE
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/__init__.py"
  INPUT "${CMAKE_CURRENT_SOURCE_DIR}/__init__.py.in"
)

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
