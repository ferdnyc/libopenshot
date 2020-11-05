# - Try to find the BlackMagic DeckLinkAPI
# Once done this will define
#
#  BLACKMAGIC_FOUND        - system has BlackMagic DeckLinkAPI installed
#  BLACKMAGIC_INCLUDE_DIR  - the include directory containing DeckLinkAPIDispatch.cpp
#  BLACKMAGIC_LIBRARY_DIR  - the directory containing libDeckLinkAPI.so
#
include(FindPackageHandleStandardArgs)

# # A user-defined environment variable is required to find the BlackMagic SDK
# if(NOT DEFINED ENV{BLACKMAGIC_DIR})
#   message(STATUS "Note: BLACKMAGIC_DIR environment variable is not defined")
# endif()

find_path(BlackMagic_INCLUDE_DIR DeckLinkAPI.h
  PATHS
    $ENV{BLACKMAGIC_DIR}
    ${BlackMagic_ROOT}
    ${BLACKMAGIC_ROOT}
    ${BLACKMAGIC_SDK_DIR}
    thirdparty/Blackmagic*
  	"/home/jonathan/Blackmagic DeckLink SDK 10.3.1"
  PATH_SUFFIXES
    Win/include
    Mac/include
    Linux/include
    include
    include/Blackmagic
    )

find_library(BlackMagic_LIBRARY DeckLinkAPI
  PATHS
    $ENV{BLACKMAGIC_DIR}
    ${BlackMagic_ROOT}
    ${BLACKMAGIC_ROOT}
    ${BLACKMAGIC_SDK_DIR}
    thirdparty/Blackmagic*
  PATH_SUFFIXES
    Win
    Mac
    Linux
  )

mark_as_advanced(
  BlackMagic_INCLUDE_DIR
  BlackMagic_LIBRARY_DIR
)

find_package_handle_standard_args(
  BlackMagic
  DEFAULT_MSG
  BlackMagic_LIBRARY_DIR
  BlackMagic_INCLUDE_DIR
)

if(BlackMagic_FOUND)
  if(NOT TARGET BlackMagic::DeckLink)
    message(STATUS "Creating IMPORTED target BlackMagic::DeckLink")

    add_library(BlackMagic::DeckLink UNKNOWN IMPORTED)

    set_target_properties(BlackMagic::DeckLink PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${BlackMagic_INCLUDE_DIR}")

    set_property(TARGET BlackMagic::DeckLink APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "HAVE_BLACKMAGIC=1")

    set_property(TARGET BlackMagic::DeckLink APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "USE_BLACKMAGIC=1")

    set_property(TARGET BlackMagic::DeckLink APPEND PROPERTY
      IMPORTED_LOCATION ${BlackMagic_LIBRARY})
