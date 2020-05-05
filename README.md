# Paracrawl processing on CSD3
This repository contains the scripts used by the University of Edinburgh for running the bitextor software on CSD3.

# Running the pipeline
Some steps are currently missing as they are not done on CSD3. Generally we assume that you already have data sharded & grouped into batches that are top out at about 1GB gzipped. (See steps 1 & 2 in the Steps section below.)

# Data structure

```
${DATA}/
  ${collection}-shards/
    ${lang}/
      ${shard}/
        ${batch}/
          plain_text.gz     : Plain text, split by HTML breaking rules. Output of
                              step 1, split/sorted into batches by step 2. Column
                              storage file where each document is a single line
                              of base64-encoded text.
          url.gz            : URL for each document, single URL per line. From
                              step 1.
          mime.gz           : Mimetype for each document, single per line. Also
                              generated during step 1.
          origin.gz         : Name of warc file document originated from
                              generated during step 2.
          sentences.gz      : Sentence-split version of plain_text.gz. Same
                              encoding, but may contain more lines in the base64
                              encoded parts (i.e some lines may be split in
                              multiple sentences.) Output of step 3.
          sentences_en.gz.  : Contains an English translation of each sentence in
                              sentences.gz. Generated during step 4.
          tokenised_en.gz.  : Tokenised version of sentences_en.gz. Generated
                              in step 5.
          aligned-[0-9].gz. : Aligned document pairs in the form of $lang-index,
                              en-index, $lang-doc, $en-doc, $lang-translated-doc
                              The number refers to the $batch in en/$shard/$batch
                              it is aligned with.

  ${collection}-batches/
    ${lang}                 : listing of paths to all batches in $lang
    01.${lang}
    ...
    05.${lang}              : generally symlinks to ${lang} listing, but can be
                              customised. These drive the job arrays. I.e. Slurms
                              ARRAY_ID matches a line in this file.
    06.${lang}              : Same as above but Cartesian product of all batches
                              in ${lang}/${shard}/* and en/${shard}/*. 

  ${collection}-corpora/
    ${collection}-unclean.en-${lang}.gz : Merged version of aligned-[0-9] with 
                                          the urls merged back into them. Input
                                          for bifixer + bicleaner.
```

# Running the pipeline
Modify `config.csd3` to your liking. Especially the paths.

Then, from the cirrus-scripts working directory, run:
```
./pipeline.sh $collection $lang...
```

This will start checking output of each step, and either schedule that step to
generate it (again) if something's wrong with it or if it is missing. It will
also schedule all the next steps. It's rather interactive, you will have to click [y] a lot.

You can run it again, or with the `-r` option, to resume or retry processing.
Effectively it is just a wrapper around calling the individual steps.

# Running individual steps (examples)
First time (assuming output from step 2 is already there). Will ask you to
confirm the number of jobs in the job-array it will schedule and then print
the Slurm job id.

```
./03.split-text.sh wide00006 is mt
```

Retry if some files didn't come through and need more time:

```
./03.split-text.sh -r --time 4:00:00 wide00006 mt
```

Checkout output of that step, will print all files that don't exist or are
corrupt to the stdout:

```
./03.split-text.check.sh wide00006 mt
```

Scheduling step 4 to directly pick up after step 3:

```
./04.translate.sh --aftercorr {job-id from step 3 here} wide00006 mt
```


## Step scripts
Each step consists of a couple of files, for example:
```
03.split-text               : Actual code executed in this step for each batch
03.split-text.sh            : Wrapper to schedule or retry step. Imports config.
03.split-text.check.sh.     : Tool to validate output of step (runs interactive)
03.split-text.slurm.        : Submission script that is submitted by the .sh
                              wrapper. Contains where and for how long each
                              step is executed, and does setup of the environment
                              on the processing node if necessary.
```

All scheduling wrappers import `functions.sh` which parses some command line
options:

```
-j | --threads          : Number of threads (for the .check.sh scripts)
-r | --retry            : Only schedule jobs where output is missing
-t time | --time time   : Override wall time limit defined in the .slurm file
--after job-id          : Run job after a previous job finished/fails/whatever
--afterok job-id        : Run job after previous job finished without error
--aftercorr job-id.     : Run each job array element after the same element of
                          a previous job finishes without error.
```

Note that the configuration is imported during submission. It uses Slurm to pick
up and transport the ENV to the eventual executed script. This way you can do
manual tweaked submissions by just sourcing the config and calling `sbatch` by
hand.

# Steps

## 01.giawarc
Splits `*.warc` files into `plain_text.gz`, `url.gz`, and `mime.gz`, split by
language. The `plain_text.gz` contains base64-encoded documents. Each document
is already split into lines according to what the HTML dictates as being on a
new line (i.e. `<li>` elements are separate lines, stuff wrapped in `<em>` wont
cause a new line, etc.)

The script in this repository is what is currently being run for wide00015 on
Cirrus, adapted to the common structure of the scripts here.

## 02.shard
Splits/merges each language's `plain_text.gz`, `url.gz` and `mime.gz` into
shards. For each document (c.f. line) in these files the domain is looked up and
hashed, which decides in which shard the document will end up. Inside that shard
the document is appended to the relative files, which are chopped into about 1GB
max size until a new batch is opened.

Note that sharding cannot be done in parallel like the other steps, we need a
merge step at the end that isn't parallel. Jelmer has been able to do most
sharding he did on Valhalla with just a single process but we can (and will
need to) use giashard and then giamerge for collections larger than wide00006.

Since this step essentially completely duplicates all data from the batches it
will have to run on Cirrus until CSD3 has more storage available...

## 03.split-text
Reads the lines from `plain_text.gz` and splits them into multiple lines if
appropriate according to the Moses sentence splitter (the Perl one).

## 04.translate
Translates each line in `sentences.gz` into English according to the parameters
in `translate.sh`. Uses `b64filter` to work on the base64-encoded docs and
`cache` to make translating all the duplications (yes, we don't bother deduping)
a bit less of a hassle.

Note that there are two variants, a CPU and a GPU one. Only Pashto right now
uses GPU translations. The submission wrapper will decide which one to submit
using the info in `translate.sh`. CPU translation happens via Moses (2...)

## 05.tokenise
This tokenises the English translation. Or in the case of English, the
sentence-split version of plain_text.gz. Uses the Moses `tokenizer.perl`.

Why? Good question. The translate script already tokenises and then detokenises
everything. The document-aligner consumes tokenised input, but bleualign does
not. Note to future: either we should just save the tokenised output from the
translation to remove this step. Note that bleualign has its own tokenisation
code. We could make bleualign just also accept the already tokenised versions of
all the input, we already have it, and it might be more consistent across the
pipeline.

## 06.align
Does document alignment using ngram scoring & sentence alignment using bleualign.

The document-aligner takes the tokenised version of the foreign documents
(translated to English) and the English documents from each of the batches in
a single shard. It then selects one English document for each foreign document.
Each document can only occur once in that output, so only 1-to-1 matches\*. 
C.f. the list of document pairs is always as long as the shortest list of 
documents.

These document pairs are then used to construct the input for bleualign, which
are the sentences (untokenised) of the documents in the pair for both languages
and their urls (but we use the document index so we can add the URL and origin
back in later.) as well as the translated version of the foreign document.

Bleualign is run in parallel using `parallel` for each document pair. The
document-aligner itself uses a producer/consumer like structure to do parallel
matching. However since its output needs to be sorted (which are the best pairs?)
it does not produce intermediate output.

## 07.unclean-corpus
Generates an uncleaned corpus that fits what is expected by bitextor. Basically
it takes the output of step 6, pastes the urls back in and concatenates it per
language in a single gzipped file under `${collection}-corpora`.

## 08 and further
See [paracrawl/clean-csd3](https://github.com/paracrawl/clean-csd3).