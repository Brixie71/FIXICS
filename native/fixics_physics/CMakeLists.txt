cmake_minimum_required(VERSION 3.21)

project(FIXICSPhysics VERSION 0.1.0 LANGUAGES CXX)

add_library(FIXICSPhysics SHARED
    src/FIXICSPhysics.cpp
)

target_compile_features(FIXICSPhysics PRIVATE cxx_std_17)

if (MSVC)
    target_compile_options(FIXICSPhysics PRIVATE /W4 /permissive-)
else()
    target_compile_options(FIXICSPhysics PRIVATE -Wall -Wextra -Wpedantic)
endif()

set(FIXICS_EXTENSION_OUTPUT_DIR "${CMAKE_SOURCE_DIR}/../..")

set_target_properties(FIXICSPhysics PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${FIXICS_EXTENSION_OUTPUT_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${FIXICS_EXTENSION_OUTPUT_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${FIXICS_EXTENSION_OUTPUT_DIR}"
    LIBRARY_OUTPUT_DIRECTORY "${FIXICS_EXTENSION_OUTPUT_DIR}"
    LIBRARY_OUTPUT_DIRECTORY_DEBUG "${FIXICS_EXTENSION_OUTPUT_DIR}"
    LIBRARY_OUTPUT_DIRECTORY_RELEASE "${FIXICS_EXTENSION_OUTPUT_DIR}"
)

if (WIN32 AND CMAKE_SIZEOF_VOID_P EQUAL 8)
    set_target_properties(FIXICSPhysics PROPERTIES OUTPUT_NAME "FIXICSPhysics_x64")
elseif (WIN32)
    set_target_properties(FIXICSPhysics PROPERTIES OUTPUT_NAME "FIXICSPhysics")
elseif (CMAKE_SIZEOF_VOID_P EQUAL 8)
    set_target_properties(FIXICSPhysics PROPERTIES OUTPUT_NAME "FIXICSPhysics_x64")
else()
    set_target_properties(FIXICSPhysics PROPERTIES OUTPUT_NAME "FIXICSPhysics")
endif()
