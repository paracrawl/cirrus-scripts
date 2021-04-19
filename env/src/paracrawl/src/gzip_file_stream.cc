#include "gzip_file_stream.hh"
#include "util/exception.hh"
#include "util/compress.hh"
#include <zlib.h>

namespace util {

// Copied from preprocess/util/compress.cc because it's not public there.
namespace {

class GZip {
  public:
    GZip() {
      stream_.zalloc = Z_NULL;
      stream_.zfree = Z_NULL;
      stream_.opaque = Z_NULL;
      stream_.msg = NULL;
    }

    void SetOutput(void *to, std::size_t amount) {
      stream_.next_out = static_cast<Bytef*>(to);
      stream_.avail_out = std::min<std::size_t>(std::numeric_limits<uInt>::max(), amount);
    }

    void SetInput(const void *base, std::size_t amount) {
      assert(amount < static_cast<std::size_t>(std::numeric_limits<uInt>::max()));
      stream_.next_in = const_cast<Bytef*>(static_cast<const Bytef*>(base));
      stream_.avail_in = amount;
    }

    const z_stream &Stream() const { return stream_; }

  protected:
    z_stream stream_;
};

class GZipWrite : public GZip {
  public:
    explicit GZipWrite(int level) {
      UTIL_THROW_IF(Z_OK != deflateInit2(
            &stream_,
            level,
            Z_DEFLATED,
            16 /* gzip support */ + 15 /* default window */,
            8 /* default */,
            Z_DEFAULT_STRATEGY), GZException, "Failed to initialize zlib decompression.");
    }

    ~GZipWrite() {
      deflateEnd(&stream_);
    }

    void Process() {
      int result = deflate(&stream_, Z_NO_FLUSH);
      UTIL_THROW_IF(Z_OK != result, GZException, "zlib encountered " << (stream_.msg ? stream_.msg : "an error ") << " code " << result);
    }

    bool Finish() {
      UTIL_THROW_IF(!stream_.avail_out, Exception, "No available output.");
      int result = deflate(&stream_, Z_FINISH);
      switch (result) {
        case Z_STREAM_END:
          return true;
        case Z_OK:
          return false;
        // "If deflate returns with Z_OK or Z_BUF_ERROR, this function must be called again with Z_FINISH and more output space"
        case Z_BUF_ERROR:
          return false;
        default:
          UTIL_THROW(GZException, "zlib encountered " << (stream_.msg ? stream_.msg : "an error ") << " code " << result);
      }
    }
};

}

class GZipCompressor : public Compressor {
public:
  GZipCompressor(int level)
  : impl_(level) {
    //
  }

  virtual ~GZipCompressor() {
    //
  }

  virtual void SetOutput(void *to, std::size_t amount) {
    impl_.SetOutput(to, amount);
  }

  virtual void SetInput(const void *base, std::size_t amount) {
    impl_.SetInput(base, amount);
  }

  virtual const void* GetOutput() const {
    return reinterpret_cast<const void *>(impl_.Stream().next_out);
  }

  virtual void Process() {
    impl_.Process();
  }

  virtual bool HasInput() const {
    return impl_.Stream().avail_in != 0;
  }

  virtual bool OutOfSpace() const {
    return impl_.Stream().avail_out < 6; /* magic number in zlib.h to avoid multiple ends */
  }

  virtual bool Finish() {
    return impl_.Finish();
  }

private:
  GZipWrite impl_; 
};

GZipFileStream::GZipFileStream(int out, int level, std::size_t buffer_size)
: CompressedFileStream(std::unique_ptr<GZipCompressor>(new GZipCompressor(level)), out, buffer_size) {
  //
}

} // 
