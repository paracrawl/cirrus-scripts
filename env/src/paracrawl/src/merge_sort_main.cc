#include <algorithm>
#include <functional>
#include <limits>
#include <string>
#include <vector>
#include <unistd.h>
#include <stdlib.h>
#include <memory>
#include <thread>
#include "util/pcqueue.hh"
#include "util/file_stream.hh"
#include "util/file_piece.hh"
#include "util/fixed_array.hh"
#include <boost/assign/list_of.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/parsers.hpp>
#include <boost/program_options/variables_map.hpp>


namespace {

template <typename Type, typename Compare = std::less<Type>>
class PriorityQueue {
public:
	explicit PriorityQueue(const Compare &compare = Compare())
	: compare_(compare) {

	}

	void push(Type &&element) {
		elements_.push_back(std::move(element));
		std::push_heap(elements_.begin(), elements_.end(), compare_);
	}

	Type pop() {
		std::pop_heap(elements_.begin(), elements_.end(), compare_);
		Type top = std::move(elements_.back());
		elements_.pop_back();
		return top;
	}

	bool empty() const {
		return elements_.empty();
	}

	void reserve(std::size_t capacity) {
		elements_.reserve(capacity);
	}

private:
	std::vector<Type> elements_;
	Compare compare_;
};

struct Options {
	std::vector<std::string> keys;
	char delimiter;
	std::string filelist;
	std::vector<std::string> files;
	std::string output;
	std::size_t thread_count;
};

enum class RangeFlags {
	none = 0,
	numeric = 1,
	reverse = 2
};

RangeFlags operator|(RangeFlags lhs, RangeFlags rhs) {
	return static_cast<RangeFlags>(
		static_cast<std::underlying_type<RangeFlags>::type>(lhs) |
		static_cast<std::underlying_type<RangeFlags>::type>(rhs)
	);
}

RangeFlags operator&(RangeFlags lhs, RangeFlags rhs) {
	return static_cast<RangeFlags>(
		static_cast<std::underlying_type<RangeFlags>::type>(lhs) &
		static_cast<std::underlying_type<RangeFlags>::type>(rhs)
	);
}

struct FieldRange {
	std::size_t begin;
	std::size_t end; // read: [begin, end)
	RangeFlags flags = RangeFlags::none;
	static const std::size_t kInfiniteEnd;
};

const std::size_t FieldRange::kInfiniteEnd = std::numeric_limits<std::size_t>::max();

bool ConsumeInt(const char *&arg, std::size_t &ret) {
	char *end;
	ret = std::strtoul(arg, &end, 10);
	
	if (arg == end)
		return false;
	
	arg = end;
	return true;
}

// Parses fields like sort does: A(,B)n?r?
FieldRange ParseRange(const char *arg) {
	FieldRange range;
	
	UTIL_THROW_IF(!ConsumeInt(arg, range.begin), util::Exception, "Expected " << arg << " to start with a number");
	UTIL_THROW_IF(range.begin == 0, util::Exception, "Sort fields start counting from 1");
	
	range.begin -= 1; // field 1 == array index 0.
	range.end = range.begin + 1; // [m,n)

	// -k 4
	if (*arg == '\0')
		return range;

	if (*arg == ',') {
		++arg; // consume comma

		// closed range: -k 4,6 or open ended range: -k 4,
		if (!ConsumeInt(arg, range.end))
			range.end = FieldRange::kInfiniteEnd;
	}

	while (*arg != '\0') {
		switch (*arg) {
			case 'n':
				range.flags = range.flags | RangeFlags::numeric;
				break;

			case 'r':
				range.flags = range.flags | RangeFlags::reverse;
				break;

			default:
				UTIL_THROW(util::Exception, "Unknown sort flag in " << arg);
		}
		++arg; // consume flag
	}

	return range;
}

struct Field {
	util::StringPiece str;
	RangeFlags flags;

	Field(util::StringPiece &&str, RangeFlags flags)
	: str(str), flags(flags) {}
};

class OutOfRange : public util::Exception {
	//
};

struct LineParser {
	std::vector<FieldRange> ranges;
	char delimiter;

	LineParser(std::vector<FieldRange> ranges, char delimiter)
	: ranges(ranges),
		delimiter(delimiter) {

	}

	template <typename StrType>
	void Parse(StrType const &str, std::vector<Field> &fields) const {
		fields.clear();
		
		// Keep offsets in case a next range refers to a previous column
		std::vector<const char *> offsets;
		offsets.push_back(0);
		
		const char *begin = str.data();
		const char *const end = str.data() + str.size();
		std::size_t column = 0;

		for (auto &&range : ranges) {
			// First catch up with current column position
			for (std::size_t i = range.begin; i < column; ++column)
				fields.emplace_back(util::StringPiece(offsets[i], offsets[i + 1] - offsets[i] - 1), range.flags); // -1 for minus delimiter
	
			// Then parse rest of line if necessary for this range			
			for (; column < range.end; ++column) {
				if (begin >= end) {
					if (range.end == FieldRange::kInfiniteEnd) {
						break;
					} else {
						UTIL_THROW(OutOfRange, "Reached end of line after reading " << column << " columns, expected at least " << range.end << " not " << FieldRange::kInfiniteEnd);
					}
				}

				auto offset = std::find(begin, end, delimiter);

				if (column >= range.begin)
					fields.emplace_back(util::StringPiece(begin, offset - begin), range.flags);

				// Keep offsets in case a next range refers to a previous column
				offsets.push_back(offset + 1);
				begin = offset + 1; // plus delimiter
			}		
		}
	}
};

// Compare numeric without trying to parse the number
int CompareNumeric(util::StringPiece const &left, util::StringPiece const &right) {
	auto li = left.begin(), ri = right.begin();

	constexpr int equal = 0;
	constexpr int left_is_smaller = -1;
	constexpr int right_is_smaller = 1;
	int flip = 1;

	// Is either empty?
	if (li == left.end())
		return ri == right.end() ? equal : left_is_smaller;
	else if (ri == right.end())
		return right_is_smaller;

	// Is only one side negative?
	if (*li == '-' && *ri != '-')
		return left_is_smaller;
	if (*li != '-' && *ri == '-')
		return right_is_smaller;
	
	// Both sides negative? 
	if (*li == '-' && *ri == '-') {
		++li;
		++ri;
		flip = -1;
	}

	// find decimal separator
	auto ld = std::find(li, left.end(), '.');
	auto rd = std::find(ri, right.end(), '.');

	// Is left side or right side larger?
	if (ld - left.begin() != rd - right.begin())
		return flip * (ld - left.begin() < rd - right.begin() ? left_is_smaller : right_is_smaller);

	// compare the part before the decimal (equal length we now know)
	int order = util::StringPiece(li, ld - li).compare(util::StringPiece(ri, rd - ri));
	if (order != 0)
		return flip * order;


	// Does either side not a have a decimal value?
	if (ld == left.end())
		return flip * (rd == right.end() ? equal : left_is_smaller);
	else if (rd == right.end())
		return flip * right_is_smaller;
	
	// compare the part after the decimal dot. Shorter value is larger value, i.e. 4.10 < 4.9
	return flip * util::StringPiece(ld + 1, left.end() - ld - 1).compare(util::StringPiece(rd + 1, right.end() - rd - 1));
}

int CompareString(util::StringPiece const &left, util::StringPiece const &right) {
	return left.compare(right);	
}

int Compare(std::vector<Field> const &left, std::vector<Field> const &right) {
	int order = 0;

	assert(left.size() == right.size());

	for (std::size_t i = 0; order == 0 && i < left.size(); ++i) {
		if ((left[i].flags & RangeFlags::numeric) == RangeFlags::numeric)
			order = CompareNumeric(left[i].str, right[i].str);
		else
			order = CompareString(left[i].str, right[i].str);

		if ((left[i].flags & RangeFlags::reverse) == RangeFlags::reverse)
			order *= -1;
	}

	return order;
}

struct Record {
	std::string str;
	std::vector<Field> fields;
};

typedef typename std::unique_ptr<Record> RecordPtr;

} // namespace

namespace std {

template <> struct greater<RecordPtr> {
	bool operator()(RecordPtr const &left, RecordPtr const &right) const {
		return Compare(left->fields, right->fields) > 0;
	}
};

} // namespace

namespace {

struct FileReader {
	std::string filename;
	LineParser const &parser;
	util::FilePiece backing;
	RecordPtr record;
	std::size_t n;
	bool eof;

	FileReader(LineParser const &parser, std::string const &filename)
	: filename(filename),
	  parser(parser),
		backing(filename.c_str()),
		n(0),
	  eof(false) {
	  	//
	}

	bool Next() {
		while (!eof) {
			util::StringPiece line;
			eof = !backing.ReadLineOrEOF(line);
			
			if (eof)
				break;

			record.reset(new Record());
			record->str = std::string(line.data(), line.size());
			
			++n;
			try {
				parser.Parse(record->str, record->fields);
				return true;
			} catch (OutOfRange const &e) {
				UTIL_THROW(util::Exception, "Parse error on line " << n << " of file " << filename << ":" << e.what());
			}
		}
		return false;
	}
};

typedef typename std::unique_ptr<FileReader> FileReaderPtr;

} // namespace

namespace std {

template <> struct greater<FileReaderPtr> {
	bool operator()(FileReaderPtr const &left, FileReaderPtr const &right) const {
		return std::greater<RecordPtr>()(left->record, right->record);
	}
};

} // namespace

namespace {

void ParseOptions(Options &opt, int argc, char** argv) {
	namespace po = boost::program_options;
	po::options_description visible("Options");
	visible.add_options()
		("key,k", po::value(&opt.keys)->default_value(boost::assign::list_of(std::string("1,")), "1,")->composing(), "Column(s) key to use as the deduplication string. Can be multiple ranges separated by commas. Each range can have n(umeric) or r(reverse) as flag.")
		("field-separator,t", po::value(&opt.delimiter)->default_value('\t'), "Field separator")
		("output,o", po::value(&opt.output)->default_value("-"), "Output file")
		("threads,j", po::value(&opt.thread_count)->default_value(4), "Thread count")
		("files-from,f", po::value(&opt.filelist), "Read file names from separate file (or '-' for stdin)")
		("help,h", "Produce help message");

	po::options_description hidden("Hidden options");
	hidden.add_options()
		("input-file", po::value(&opt.files), "Input files");

	po::positional_options_description positional;
	positional.add("input-file", -1);

	po::options_description opts;
	opts.add(visible).add(hidden);

	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(opts).positional(positional).run(), vm);
	po::notify(vm);

	if (vm.count("help")) {
		std::cerr << "Usage: [-k key] [-t delim] [-h] [-f filelist] [file ...]" << "\n"
		          << "\n" << visible << "\n";
		std::exit(1);
	}
}

void ReadFileList(util::FilePiece &filelist, std::vector<std::string> &filenames) {
	for (util::StringPiece &&filename : filelist)\
		if (!filename.empty())
			filenames.push_back(std::string(filename.data(), filename.size()));
}

std::size_t CeilDiv(std::size_t x, std::size_t y) {
	return (x + y - 1) / y;
}

struct Worker {
	// Accessed by thread
	LineParser const &parser;
	util::PCQueue<RecordPtr> queue;
	std::vector<std::string> filenames;

	// Accessed from main thread
	RecordPtr record;
	bool eof;
	std::thread thread;

	Worker(LineParser const &parser, std::vector<std::string> &&filenames)
	: parser(parser),
	  queue(1024), // Buffer size?
	  filenames(std::move(filenames)),
	  eof(false),
	  thread([this]() { (*this)(); }) {

	}

	void operator()() {
		PriorityQueue<FileReaderPtr, std::greater<FileReaderPtr>> files;
		files.reserve(filenames.size());

		for (auto &&filename : filenames) {
			FileReaderPtr reader(new FileReader(parser, filename));

			// Read the first line. If the file ends up empty, don't add it.
			if (reader->Next())
				files.push(std::move(reader));
		}
		
		while (!files.empty()) {
			FileReaderPtr top(files.pop());
			queue.ProduceSwap(top->record);
			if (top->Next())
				files.push(std::move(top));
		}

 		// Notify of eof
		RecordPtr poison;
		queue.ProduceSwap(poison);
	}

	void Next() {
		if (!queue.ConsumeSwap(record))
			eof = true;
	}
};

typedef typename std::unique_ptr<Worker> WorkerPtr;

void Process(std::vector<WorkerPtr> &&workers, util::FileStream &out) {
	// First consume to get that first record here on the main thread
	for (WorkerPtr const &worker : workers)
		worker->Next();

	while (true) {
		Worker *best = nullptr;

		for (WorkerPtr const &worker : workers) {
			if (worker->eof)
				continue;

			if (!best || std::greater<RecordPtr>()(best->record, worker->record))
				best = worker.get(); // unsafe ptr, but never leaves this while loop
		}

		if (!best) // all workers eof
			break;

		out << best->record->str << '\n';
		best->Next();
	}

	// Just nicely finish up (they have all ended already because they eof'ed but
	// I want to be very sure I don't free up resources that may still be in use.)
	for (WorkerPtr const &worker : workers)
		worker->thread.join();
}

} // namespace

int main(int argc, char** argv) {
	Options options;
	ParseOptions(options, argc, argv);

	// Interpret sort ranges
	std::vector<FieldRange> ranges;
	for (std::string const &key : options.keys)
		ranges.push_back(ParseRange(key.c_str()));

	// Read file list (if provided)
	if (options.filelist == "-") {
		auto list = util::FilePiece(STDIN_FILENO);
		ReadFileList(list, options.files);
	} else if (!options.filelist.empty()) {
		auto list = util::FilePiece(options.filelist.c_str());
		ReadFileList(list, options.files);
	}

	LineParser parser(ranges, options.delimiter);

	std::vector<WorkerPtr> workers;
	workers.reserve(options.thread_count);

	// Divide files among the workers and start the workers
	for (std::size_t i = 0; i < options.thread_count; ++i) {
		std::vector<std::string> filenames;
		filenames.reserve(CeilDiv(options.files.size(), options.thread_count));

		for (std::size_t n = i; n < options.files.size(); n += options.thread_count)
			filenames.push_back(options.files[n]);

		workers.emplace_back(new Worker(parser, std::move(filenames)));
	}
	
	if (options.output == "-") {
		util::FileStream out(STDOUT_FILENO);
		Process(std::move(workers), out);
	} else {
		util::scoped_fd fout(util::CreateOrThrow(options.output.c_str()));
		util::FileStream out(fout.get());
		Process(std::move(workers), out);
	}

	return 0;
}
