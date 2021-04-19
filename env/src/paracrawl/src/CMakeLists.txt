set(COMPRESS_FLAGS)
set(COMPRESS_LIBS)
find_package(ZLIB)
if (ZLIB_FOUND)
  set(COMPRESS_FLAGS "${COMPRESS_FLAGS} -DHAVE_ZLIB")
  set(COMPRESS_LIBS ${COMPRESS_LIBS} ${ZLIB_LIBRARIES})
  include_directories(${ZLIB_INCLUDE_DIR})
endif()

set_source_files_properties(compressed_file_stream.cc PROPERTIES COMPILE_FLAGS ${COMPRESS_FLAGS})

add_library(paracrawl_util
  gzip_file_stream.cc
  gzip_file_stream.hh
)

target_link_libraries(paracrawl_util preprocess_util)

# Explicitly list the executable files to be compiled
set(EXE_LIST
  batch_dedupe
  merge_sort
)

foreach(exe ${EXE_LIST})
  add_executable(${exe} ${exe}_main.cc)
  target_link_libraries(${exe} paracrawl_util ${PREPROCESS_LIBS})
  set_target_properties(${exe} PROPERTIES FOLDER executables)
endforeach(exe)
