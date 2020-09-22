# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#[=======================================================================[.rst:
CMakePrintHelpers
-----------------

Convenience functions for printing properties and variables, useful
e.g. for debugging.

::

  cmake_print_properties([  TARGETS target1 ..  targetN
                          | SOURCES source1 .. sourceN
                          | DIRECTORIES dir1 .. dirN
                          | TESTS test1 .. testN
                          | CACHE_ENTRIES entry1 .. entryN ]
                         PROPERTIES prop1 .. propN )

This function prints the values of the properties of the given targets,
source files, directories, tests or cache entries.  Exactly one of the
scope keywords must be used.  Example::

  cmake_print_properties(TARGETS foo bar PROPERTIES
                         LOCATION INTERFACE_INCLUDE_DIRECTORIES)

This will print the LOCATION and INTERFACE_INCLUDE_DIRECTORIES properties for
both targets foo and bar.

::

  cmake_print_variables(var1 var2 ..  varN)

This function will print the name of each variable followed by its value.
Example::

  cmake_print_variables(CMAKE_C_COMPILER CMAKE_MAJOR_VERSION DOES_NOT_EXIST)

Gives::

  -- CMAKE_C_COMPILER="/usr/bin/gcc" ; CMAKE_MAJOR_VERSION="2" ; DOES_NOT_EXIST=""
#]=======================================================================]

function(cmake_print_variables)
  set(msg "")
  foreach(var ${ARGN})
    if(msg)
      string(APPEND msg " ; ")
    endif()
    string(APPEND msg "${var}=\"${${var}}\"")
  endforeach()
  message(STATUS "${msg}")
endfunction()

set(modes TARGETS SOURCES TESTS DIRECTORIES CACHE_ENTRIES)
set(keyword_TARGETS TARGET)
set(keyword_SOURCES SOURCE)
set(keyword_TESTS TEST)
set(keyword_DIRECTORIES DIRECTORY)
set(keyword_CACHE_ENTRIES CACHE_ENTRY)

function(cmake_print_properties)
  set(options )
  set(oneValueArgs )
  set(multiValueArgs ${_modes} PROPERTIES )

  cmake_parse_arguments(CPP "${options}" "${oneValueArgs}" "${multiValueArgs}"  ${ARGN})

  if(CPP_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown keywords given to cmake_print_properties(): \"${CPP_UNPARSED_ARGUMENTS}\"")
    return()
  endif()

  if(NOT CPP_PROPERTIES)
    message(FATAL_ERROR "Required argument PROPERTIES missing in cmake_print_properties() call")
    return()
  endif()

  set(used_modes)
  set(items)
  set(keyword)

  foreach(${mode} ${modes})
    if(CPP_${mode})
      list(APPEND used_modes ${mode})
      set(items ${CPP_${mode}})
      set(keyword ${keyword_${mode}})
    endif()
  endforeach()

  if(NOT used_modes)
    message(FATAL_ERROR "Mode keyword missing in cmake_print_properties() call, it must be one of ${modes}")
    return()
  endif()

  list(LENGTH used_modes usedLength)
  if("${usedLength}" GREATER 1)
    message(FATAL_ERROR "Multiple mode keywords used in cmake_print_properties() call, there must be exactly one of ${modes}")
    return()
  endif()

  set(msg "\n")
  foreach(item ${items})

    set(itemExists TRUE)
    if(keyword STREQUAL "TARGET")
      if(NOT TARGET ${item})
      set(itemExists FALSE)
      string(APPEND msg "\n No such TARGET \"${item}\" !\n\n")
      endif()
    endif()

    if (itemExists)
      string(APPEND msg " Properties for ${keyword} ${item}:\n")
      foreach(prop ${CPP_PROPERTIES})

        get_property(propertySet ${keyword} ${item} PROPERTY "${prop}" SET)

        if(propertySet)
          get_property(property ${keyword} ${item} PROPERTY "${prop}")
          string(APPEND msg "   ${item}.${prop} = \"${property}\"\n")
        else()
          string(APPEND msg "   ${item}.${prop} = <NOTFOUND>\n")
        endif()
      endforeach()
    endif()

  endforeach()
  message(STATUS "${msg}")

endfunction()
