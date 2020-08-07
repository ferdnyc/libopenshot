####################### CMakeLists.txt (libopenshot) #########################
# @brief CMake build file for libopenshot (used to generate makefiles)
# @author Jonathan Thomas <jonathan@openshot.org>
# @author FeRD (Frank Dana) <ferdnyc@gmail.com>
#
# @section LICENSE
#
# Copyright (c) 2008-2020 OpenShot Studios, LLC
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

include(GNUInstallDirs)

if(POLICY CMP0083)
  cmake_policy(SET CMP0083 NEW)
endif()

if(NOT DEFINED OPENSHOT_LIB_TARGETS)
  set(OPENSHOT_LIB_TARGETS openshot OpenShot::Audio)
endif()

# Dependencies
find_package(Qt5 COMPONENTS Gui REQUIRED)

# Define path to test input files
file(TO_NATIVE_PATH "${PROJECT_SOURCE_DIR}/examples/" TEST_MEDIA_PATH)

############### CLI EXECUTABLES ################
# Create test executable
add_executable(openshot-example Example.cpp)
target_compile_definitions(openshot-example PRIVATE
	-DTEST_MEDIA_PATH="${TEST_MEDIA_PATH}" )
target_link_libraries(openshot-example openshot_obj openshot_deps)

add_executable(openshot-html-test ExampleHtml.cpp)
target_link_libraries(openshot-html-test openshot_obj openshot_deps)

############### PLAYER EXECUTABLE ################
# Create test executable
if(ENABLE_BUNDLED)
  add_executable(openshot-player qt-demo/main.cpp $<TARGET_OBJECTS:openshot_obj>)
  set_target_properties(openshot-player PROPERTIES
    AUTOMOC ON
    POSITION_INDEPENDENT_CODE ON
    )

else()
  add_executable(openshot-player qt-demo/main.cpp)
endif()

# Link test executable to the new library
target_link_libraries(openshot-player openshot_deps)

############### TEST BLACKMAGIC CAPTURE APP ################
if (BLACKMAGIC_FOUND)
	# Create test executable
	add_executable(openshot-blackmagic
			examples/ExampleBlackmagic.cpp)

	# Link test executable to the new library
  target_link_libraries(openshot-blackmagic ${OPENSHOT_LIB_TARGETS})
endif()
