#include "compressed_file_stream.hh"

namespace util {

class GZipFileStream : public CompressedFileStream {
public:
  explicit GZipFileStream(int out = -1, int level = 9, std::size_t buffer_size = 8192);
};

}
