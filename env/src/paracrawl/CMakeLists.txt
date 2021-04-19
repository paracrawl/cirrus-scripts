cmake_minimum_required(VERSION 2.8.12)

# Define a single cmake project
project(paracrawl)

set(CMAKE_CXX_STANDARD 11)

set(CMAKE_CXX_FLAGS "-Wall -Wextra")

set(CMAKE_CXX_FLAGS_RELEASE "-O3 -Ofast")

if(MSVC)
  set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} /w34716")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /w34716")
endif()

if (NOT MSVC)
  set(THREADS pthread)
endif()

# Compile all executables into bin/
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

# Compile all libraries into lib/
set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib)

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

# We need boost
find_package(Boost 1.41.0 REQUIRED COMPONENTS
  program_options
  filesystem
)

set(PREPROCESS_PATH "../preprocess")
set(PREPROCESS_LIBS preprocess_util ${Boost_LIBRARIES} ${THREADS})
add_subdirectory(${PREPROCESS_PATH} build)

include_directories(
  ${PROJECT_SOURCE_DIR}
  ${PREPROCESS_PATH}
  ${Boost_INCLUDE_DIRS}
)

add_subdirectory(src)
