# - Try to find JUCE-based OpenShot Audio Library
#
# On success this module will set the variable OpenShotAudio_FOUND
# to TRUE, and create the following IMPORTED target:
#
#    OpenShot::Audio
#
# The Find module supports QUIET and REQUIRED standard args, as well as
# the VERSION parameter to specify the minimum compatible libopenshot-audio
# release.
#
# The following legacy variables are also set, for compatibility
#
#  OpenShotAudio_INCLUDE_DIRS - The library include directory path
#  OpenShotAudio_LIBRARIES    - The location of the library

if(DEFINED ENV{LIBOPENSHOT_AUDIO_DIR}
   OR DEFINED LIBOPENSHOT_AUDIO_DIR
   OR DEFINED OpenShotAudio_DIR)

  # Warn the user about old variables, if we're allowed to be noisy
  if(NOT OpenShotAudio_FIND_QUIETLY)
    message(WARNING [==[
Legacy variables for locating libopenshot-audio, including LIBOPENSHOT_AUDIO_DIR and OpenShotAudio_DIR, are deprecated. Use the CMake-supported 'OpenShotAudio_ROOT' command-line/cache variable to specify the libopenshot-audio search path.]==])
  endif()

  # Migrate any legacy values to OpenShotAudio_ROOT, if possible
  # (We still also check them below, for the time being)
  if(DEFINED ENV{LIBOPENSHOT_AUDIO_DIR} AND NOT DEFINED OpenShotAudio_ROOT)
    set(OpenShotAudio_ROOT $ENV{LIBOPENSHOT_AUDIO_DIR})
  elseif(DEFINED LIBOPENSHOT_AUDIO_DIR AND NOT DEFINED OpenShotAudio_ROOT)
    set(OpenShotAudio_ROOT ${LIBOPENSHOT_AUDIO_DIR})
  elseif(DEFINED OpenShotAudio_DIR AND NOT DEFINED OpenShotAudio_ROOT)
    set(OpenShotAudio_ROOT ${OpenShotAudio_DIR})
  endif()
endif()

if(DEFINED OpenShotAudio_ROOT AND NOT OpenShotAudio_FIND_QUIETLY)
  message(STATUS "Looking for OpenShotAudio in ${OpenShotAudio_ROOT}")
endif()

# Find the libopenshot-audio header files (check env/cache vars first)
find_path(
  OpenShotAudio_INCLUDE_DIR
  JuceHeader.h
  PATHS
    ENV LIBOPENSHOT_AUDIO_DIR
    ${OpenShotAudio_ROOT}
    ${LIBOPENSHOT_AUDIO_DIR}
    ${OpenShotAudio_DIR}
  PATH_SUFFIXES
    include/libopenshot-audio
    libopenshot-audio
    include
  NO_DEFAULT_PATH
)

# Find the libopenshot-audio header files (fallback to std. paths)
find_path(
  OpenShotAudio_INCLUDE_DIR
  JuceHeader.h
  PATHS
    ENV LIBOPENSHOT_AUDIO_DIR
    ${OpenShotAudio_ROOT}
    ${LIBOPENSHOT_AUDIO_DIR}
    ${OpenShotAudio_DIR}
  PATH_SUFFIXES
    include/libopenshot-audio
    libopenshot-audio
    include
)

# Find libopenshot-audio.so / libopenshot-audio.dll (check env/cache vars first)
find_library(
  OpenShotAudio_LIBRARY
  NAMES
    libopenshot-audio
    openshot-audio
  HINTS
    ENV LIBOPENSHOT_AUDIO_DIR
  PATHS
    ${OpenShotAudio_ROOT}
    ${LIBOPENSHOT_AUDIO_DIR}
    ${OpenShotAudio_DIR}
  PATH_SUFFIXES
    lib/libopenshot-audio
    libopenshot-audio
    lib
  NO_DEFAULT_PATH
)

# Find libopenshot-audio.so / libopenshot-audio.dll (fallback)
find_library(
  OpenShotAudio_LIBRARY
  NAMES
    libopenshot-audio
    openshot-audio
    ${OpenShotAudio_DIR}
  PATHS
    ENV LIBOPENSHOT_AUDIO_DIR
    ${OpenShotAudio_ROOT}
    ${LIBOPENSHOT_AUDIO_DIR}
  PATH_SUFFIXES
    lib/libopenshot-audio
    libopenshot-audio
    lib
)

if(OpenShotAudio_INCLUDE_DIR AND OpenShotAudio_LIBRARY)
  set(OpenShotAudio_FOUND TRUE)
endif()

# XXX: Debugging, don't leave this here
message(STATUS "OpenShotAudio header path: ${OpenShotAudio_INCLUDE_DIR}")

#
# Create the IMPORTED target
#
if (OpenShotAudio_FOUND AND NOT TARGET OpenShot::Audio)

  add_library(OpenShot::Audio UNKNOWN IMPORTED GLOBAL)

  set_property(TARGET OpenShot::Audio PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES ${OpenShotAudio_INCLUDE_DIR})

  set_property(TARGET OpenShot::Audio PROPERTY
    IMPORTED_LOCATION ${OpenShotAudio_LIBRARY})

  # Include the -NDEBUG definition for Release builds
  set_property(TARGET OpenShot::Audio APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS $<$<CONFIG:Release>:NDEBUG>)

  # Set some compiler options for Windows
  # required for libopenshot-audio headers
  if(WIN32)
    set_property(TARGET OpenShot::Audio APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS IGNORE_JUCE_HYPOT=1)
    set_property(TARGET OpenShot::Audio APPEND PROPERTY
      INTERFACE_COMPILE_OPTIONS "-include cmath")
  endif()

  # Apple has its own quirks
  if (APPLE)
    foreach(_lib IN
      "-framework Carbon"
      "-framework Cocoa"
      "-framework CoreFoundation"
      "-framework CoreAudio"
      "-framework CoreMidi"
      "-framework IOKit"
      "-framework AGL"
      "-framework AudioToolbox"
      "-framework QuartzCore"
      "-framework Accelerate"
      -lobjc )
      set_property(TARGET OpenShot::Audio APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES ${_lib})
    endforeach()
  endif()

endif()

#
# Version parsing and requirements verification
#
if(OpenShotAudio_INCLUDE_DIR AND EXISTS "${OpenShotAudio_INCLUDE_DIR}/JuceHeader.h")
  file(STRINGS "${OpenShotAudio_INCLUDE_DIR}/JuceHeader.h" _osa_version_str
       REGEX "versionString.*=.*\"[^\"]+\"")
  if(_osa_version_str MATCHES "versionString.*=.*\"([^\"]+)\"")
    set(OpenShotAudio_VERSION_STRING ${CMAKE_MATCH_1})
  endif()
  unset(_osa_version_str)
  string(REGEX REPLACE "^([0-9]+\.[0-9]+\.[0-9]+).*$" "\\1"
         OpenShotAudio_VERSION "${OpenShotAudio_VERSION_STRING}")
endif()

# If we couldn't parse M.N.P version, don't keep any of it
if(NOT OpenShotAudio_VERSION)
  unset(OpenShotAudio_VERSION)
  unset(OpenShotAudio_VERSION_STRING)
endif()

# Determine compatibility with requested version in find_package()
if(OpenShotAudio_FIND_VERSION AND OpenShotAudio_VERSION)
  if("${OpenShotAudio_FIND_VERSION}" STREQUAL "${OpenShotAudio_VERSION}")
    set(OpenShotAudio_VERSION_EXACT TRUE)
  endif()
  if("${OpenShotAudio_FIND_VERSION}" VERSION_GREATER "${OpenShotAudio_VERSION}")
    set(OpenShotAudio_VERSION_COMPATIBLE FALSE)
  else()
    set(OpenShotAudio_VERSION_COMPATIBLE TRUE)
  endif()
endif()

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments and set OpenShotAudio_FOUND to TRUE
# if all listed variables are TRUE
find_package_handle_standard_args(OpenShotAudio
  REQUIRED_VARS
    OpenShotAudio_LIBRARY
    OpenShotAudio_INCLUDE_DIR
  VERSION_VAR
    OpenShotAudio_VERSION_STRING
)
# Package metadata for FeatureSummary
set_property(GLOBAL PROPERTY
  _CMAKE_OpenShotAudio_DESCRIPTION
   "OpenShot audio library based on JUCE"
)
set_property(GLOBAL PROPERTY
  _CMAKE_OpenShotAudio_URL
  https://github.com/OpenShot/libopenshot-audio
)

# Excessive backwards-compatibility. Note that this won't export all of
# the compile definitions and extra libs that the target does, so it's
# still preferable to use the target.
set(OpenShotAudio_LIBRARY "${OpenShotAudio_LIBRARY}")
set(OpenShotAudio_LIBRARIES "${OpenShotAudio_LIBRARY}")
set(OpenShotAudio_INCLUDE_DIRS "${OpenShotAudio_INCLUDE_DIR}")
set(LIBOPENSHOT_AUDIO_LIBRARY "${OpenShotAudio_LIBRARY}")
set(LIBOPENSHOT_AUDIO_LIBRARIES "${OpenShotAudio_LIBRARY}")
set(LIBOPENSHOT_AUDIO_INCLUDE_DIR "${OpenShotAudio_INCLUDE_DIR}")
set(LIBOPENSHOT_AUDIO_INCLUDE_DIRS "${OpenShotAudio_INCLUDE_DIR}")
