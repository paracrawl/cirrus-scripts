# Paracrawl pipeline for non-Paracrawlers:
See [this tutorial](https://docs.google.com/document/d/1YyjdWofZ65ib9qTnGiJ8n0Rvgm4PKRhwvnFYfXrSMRg/edit?usp=sharing), much more readable. If anything is unclear ping me on Slack and/or leave a comment in the Google document.

# Paracrawl processing on CSD3
This repository contains the scripts used by the University of Edinburgh for running the bitextor software on CSD3.

# Running the pipeline
Some steps are currently missing as they are not done on CSD3. Generally we assume that you already have data sharded & grouped into batches that are top out at about 1GB gzipped. (See steps 1 & 2 in the Steps section below.)

# Data structure

```
${COLLECTIONS[$collection]}/
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
    01.$lang
    ...
    05.$lang                : generally symlinks to ${lang} listing, but can be
                              customised. These drive the job arrays. I.e. Slurms
                              ARRAY_ID matches a line in this file.
    06.$lang-$TARGET_LANG   : Same as above but Cartesian product of all batches
                              in ${lang}/${shard}/* and en/${shard}/*.
    09.$lang-$TARGET_LANG
    ...
    11.$lang-$TARGET_LANG   : List of 1GB chunks of an unclean corpus that need
                              to be cleaned.

  ${collection}-corpora/
    ${collection}-unclean.en-${lang}.gz : Merged version of aligned-[0-9] with 
                                          the urls merged back into them. Input
                                          for bifixer + bicleaner.

  ${collection}-cleaning/
    ${TARGET_LANG}-${lang}/
      0000.raw              : Unclean sentence pairs, split in chunks of 1GB.
      0000.classified.gz    : Output of bicleaner, quality classification.
      0000.filtered??.gz    : Segment of classification that meets threshold.
      0000.stats            : line count and word count of filtered segment.

  ${DATA}/cleaning/
    ${TARGET_LANG}-${lang}/
      ${TARGET_LANG}-${lang}.${collections} …
      [..].classified.gz    : Concatenation of all classified sentence pairs
      [..].filtered??.gz    : Concatenation of all classified sentence pairs
                              that met the threshold value.
      [..].tmx.gz           : Deduplicated tmx file generated from the filtered
                              sentence pairs.
      [..].txt.gz           : Simple $TARGET_LANG [tab] $lang txt file of all
                              deduplicated sentence pairs. Derived from tmx file.
      
```

# Compiling software
Note: these notes are only tested on CSD3, and this process relies on modules
that are probably only available on CSD3. Try this elsewhere at your own peril.

First of all, make sure you check out all submodules:
```sh
git submodule update --init --recursive
```

In the `env/` directory you'll find a couple of files:
```
env/
  setup.sh                  : Script to download & compile software into this
                              env/ folder. It will also make this a python
                              virtual env so that installations via pip will end
                              up in here.
  init.sh                   : Sets the env/ up as a valid location to search for
                              compiled software. Similar to Python's virtualenv
                              `activate` script.
  shell.sh                  : Shortcut to open a shell with the environment
                              set-up.
  clean.sh                  : Removes all compiled code again. For when you want
                              to run setup.sh with a clean start.
  setup.d/                  : Recipes for compiling dependencies. Used by 
                              setup.sh.
  src/                      : Mostly submodules checked out via git. Some
                              dependencies will be downloaded via setup.sh.
  bin/, lib/, include/ ...  : The actual environment once it has been set up.
```

If you just need specific software, like bicleaner and bitextor, you can do this.
The setup.sh script will figure out the dependencies.
```
./setup.sh install bicleaner bitextor
```

If you expect to need everything, just do
```
./setup.sh install-all
```

To see what's already installed, you can use
```
./setup.sh status
```

Dependencies per step:
01: giawarc  
02: giashard  
03: preprocess  
04: preprocess; maybe marian-fbgemm, moses2, subword, depends on your translation model  
05: preprocess; maybe jieba, mecab  
06: preprocess docalign bleualign  
07:  
08:  
09: preprocess bifixer bicleaner  
10:  
11:  
12: tmxt  


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
03.split-text.check.sh.     : Tool to validate output of step (runs interactive)
03.split-text.sh            : Submission script that sets SLURM parameters.
```

Most scripts use `generic.slurm` as their "slurm" wrapper. This script functions
a bit like `xargs`, in that it will run the command passed to it for each line
in the batch list that is passed in as it's first argument. If it was started
with --ntasks > 1, it will run ntasks in parallel. (To offload SLURM when there
are many many batches to process, we have our own parallel executor.)

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

## Environment variables
You can also control how many batches are to be processed per slurm job. For
example, each job array job can process 64 batches, 4 in parallel by doing:
```sh
TPB=64 TPN=4 ./06.align.sh wide00006 zh
```

- **TPB**: tasks per "batch", which I now realise is exactly the opposite of
"batches per task", which is the actual meaning…. Defaults to 1.
- **TPN**: tasks per node, which translates to Slurm's --ntasks argument. Note that
this defaults to the same value as TPB.
- **SBATCH**: allows you to override which program is called for `sbatch` by
the schedule function in `functions.sh`. Useful for debugging, i.e. calling it
with `fake-sbatchs.sh` which will just run the task instead of scheduling it.

Note that the configuration is imported during submission. It uses Slurm to pick
up and transport the ENV to the eventual executed script. This way you can do
manual tweaked submissions by just sourcing the config and calling `sbatch` by
hand, and you can change `config.csd3` without impacting already scheduled jobs.

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

```sh
./07.unclean-corpus.sh wide00015 zh
```

This command has no "resume" or "retry" option. It just concatenates everything
it can find. If something was missing, you will have to concat again.

**Note**: From here on the scripts are more or less copied over from
[paracrawl/clean-csd3](https://github.com/paracrawl/clean-csd3). If you have a 
low resource language, you can also just use `clean.sh` which concatenates all
of the following steps into a single script.

## 08.extract
Takes the uncleaned corpus and splits it into chunks of 1GB again.

```sh
./08.extract.sh wide00015 zh
```

Bit odd to first have shards & batches, then combine all of them, and then split
then again right? I agree, and I would like to change it. But with the current
set-up you'll see that some shards will yield much more than 1GB of sentence
pairs while others will just yield a few kb. Some domains are just more
interesting than others. Or larger. (I'm looking at you, dropbox.com…) By
concatenating and then splitting again we're balancing them out again so all the
cleaning job will run in about the same amount of time.

This step generates a whole bunch of
`${COLLECTION[$collection]}-cleaning/en-zh/????.raw` files, each plain text.

Note that this command has no resume option at this moment. If you suddenly
find more shard/batches, you wll have to re-run step 7 and that will invalidate
all the work done from that point on.

## 09.clean
Takes all the unclean chunks and pulls them through bifixer and bicleaner.

bifixer fixes unicode errors, whitespace issues, etc. More importantly for the
pipeline, it generates a hash that identifies the sentence pair. This hash is
later used to deduplicate very similar sentence pairs from the tmx file.

bicleaner classifies the quality of a sentence pair. This score is then used to
filter out low quality sentence pairs (see `BICLEANER_THRESHOLD` in `config.csd3`)

This step generates the 
`$COLLECTIONS[$collection]-cleaning/en-zh/????.{classfied,filtered04}.gz} files.

## 10.reduce-classified
Just concatenates all classified sentence pair chunks. Not necessary for anything
further down the pipeline, but paracrawl also publishes these files.

**Note** the order of the arguments is now flipped because this step can be
used to combine multiple collections into a single release.

```sh
./10.reduce-classified.sh zh wide00006 wide00015 hieu
```

This generates a file named 
`$DATA/cleaning/en-zh/en-zh.hieu-wide00006-wide00015.classified.gz`.

## 11.reduce-filtered
Concatenates all filtered sentence pair chunks.

```sh
./11.reduce-filtered.sh zh wide00006 wide000015 hieu
```

The output will be something like 
`$DATA/cleaning/en-zh/en-zh.hieu-wide00006-wide00015.filtered04.gz`.

This step can be run in parallel to 10.

## 12.reduce-tmx
Needs the output of step 11.

Generates a tmx file. In this step the sentence pairs are deduplicated. The urls
are maintained, so a single sentence pair can have multiple urls pointing to all
the documents it occurred in, after filtering.

The tmx file may also contain additional hints dropped by bicleaner for each
sentence pair, and the collections where the sentence pair originates from.

This tmx file is also immediately used to derive a txt file with just the
sentence pairs. No urls, no scores, etc.

```sh
./12.reduce-tmx.sh zh wide00006 wide00015 zh
```

The output will be in 
`$DATA/cleaning/en-zh.hieu-wide00006-wide00015.{tmx,txt}.gz`.

Note: Step 11 and 12 are not combined because step 11 needs many resources to
sort all sentence pairs. Step 12 consists of just a single-threaded python
script. It would be wasteful to hold up all the resources step 11 needed just
because that python script in step 12 takes such a long time to finish. Hence
step 12 is separate and asks for fewer resources.
