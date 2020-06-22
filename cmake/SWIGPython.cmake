
message(STATUS "Configuring SWIG Python module")

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

find_package(SWIG 3.0 REQUIRED)
include(${SWIG_USE_FILE})

set(SWIG_FILE ${PROJECT_SOURCE_DIR}/bindings/openshot.i)

### Suppress a ton of warnings in the generated SWIG C++ code
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  set(SWIG_CXX_FLAGS "-Wno-unused-variable -Wno-unused-function \
    -Wno-deprecated-copy -Wno-class-memaccess -Wno-cast-function-type \
    -Wno-unused-parameter -Wno-catch-value -Wno-sign-compare -Wno-ignored-qualifiers")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(SWIG_CXX_FLAGS "-Wno-unused-variable -Wno-unused-function \
    -Wno-deprecated-copy -Wno-class-memaccess -Wno-cast-function-type \
    -Wno-unused-parameter -Wno-catch-value -Wno-sign-compare -Wno-ignored-qualifiers")
endif()
separate_arguments(sw_flags UNIX_COMMAND ${SWIG_CXX_FLAGS})
set_property(SOURCE ${SWIG_FILE} PROPERTY GENERATED_COMPILE_OPTIONS ${sw_flags})

if (CMAKE_VERSION VERSION_LESS 3.13.0)
  include_directories(${PROJECT_SOURCE_DIR}/src ${PROJECT_BINARY_DIR}/src)
endif()

### Enable C++ support in SWIG
set_property(SOURCE ${SWIG_FILE} PROPERTY CPLUSPLUS ON)

separate_arguments(sw_flags UNIX_COMMAND ${SWIG_CXX_FLAGS})
set_property(SOURCE ${SWIG_FILE} PROPERTY GENERATED_COMPILE_OPTIONS ${sw_flags})

### Take include dirs from target, automatically if possible
if (CMAKE_VERSION VERSION_GREATER 3.13)
	set_property(SOURCE ${SWIG_FILE} PROPERTY USE_TARGET_INCLUDE_DIRECTORIES True)
endif ()

find_package(PythonInterp 3)
find_package(PythonLibs 3)

include_directories(${PYTHON_INCLUDE_PATH})

### Add the SWIG interface file (which defines all the SWIG methods)
if (CMAKE_VERSION VERSION_LESS 3.8.0)
	swig_add_module(pyopenshot python ${SWIG_FILE})
else()
	swig_add_library(pyopenshot
	  LANGUAGE python
	  SOURCES ${SWIG_FILE}
  )
endif()

### Set output name and configs propagation for target
set_target_properties(${SWIG_MODULE_pyopenshot_REAL_NAME} PROPERTIES
  PREFIX "_"
  OUTPUT_NAME "openshot"
  SWIG_USE_TARGET_INCLUDE_DIRECTORIES TRUE
  SWIG_USE_TARGET_COMPILE_DEFINITIONS TRUE
  SWIG_USE_TARGET_COMPILE_OPTIONS TRUE
)

# Link with Python (libopenshot linking will be handled later)
# XXX: Bad idea, apparently, see the advice in PEP-513:
# https://www.python.org/dev/peps/pep-0513/#id41
#target_link_libraries(${SWIG_MODULE_pyopenshot_REAL_NAME} PUBLIC
#  ${PYTHON_LIBRARIES}
#)

# Pass the target name back to our caller
set(SWIG_PYTHON_TARGET ${SWIG_MODULE_pyopenshot_REAL_NAME})
