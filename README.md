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
          aligned-[0-9].gz. : Aligned sentence pairs in the form of $lang-index,
                              en-index, $lang-doc, $en-doc, $lang-translated-doc
                              The number refers to the $batch in en/$shard/$batch
                              it is aligned with.
          fixed.gz          : All aligned document pairs concatenated, and
                              processed with bifixer. Produced in step 07.
          hardruled.gz      : bicleaner-hardrules.py scores of fixed.gz, with 0 for
                              lines that should be ignored further down the pipeline.
          scored.gz         : bicleaner-ai score column for fixed.gz
                              (or 0 for those lines that got marked 0 by hardrules.)
                              Produced in step 08, on GPU.
          classified.gz     : fixed.gz, combined with the score column and source
                              collection column (and takedown sentences removed)
          filtered05.gz     : File above, but filtered by score.

  ${collection}-batches/
    ${lang}                 : listing of paths to all batches in $lang
    01.$lang
    ...
    05.$lang                : generally symlinks to ${lang} listing, but can be
                              customised. These drive the job arrays. I.e. Slurms
                              ARRAY_ID matches a line in this file.
    06.$lang-$TARGET_LANG   : Same as above but Cartesian product of all batches
                              in ${lang}/${shard}/* and en/${shard}/*.
    07.$lang-$TARGET_LANG
    ...
    12.$lang-$TARGET_LANG   : Same as 05 really.

  ${DATA}/clean/
    ${TARGET_LANG}-${lang}/
      ${TARGET_LANG}-${lang}.${collections} …
      [..].classified.gz    : Concatenation of all classified sentence pairs
      [..].filtered??.gz    : Concatenation of all classified sentence pairs
                              that met the threshold value.
      [..].tmx.gz           : Deduplicated tmx file generated from the filtered
                              sentence pairs.
      [..].deferred.tmx.gz  : Same as above, but without the sentences themselves.
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
01: warc2text  
02: giashard, batch_dedupe  
03: preprocess  
04: preprocess; maybe marian-dev, moses2, subword, depends on your translation model  
05: preprocess; maybe jieba, mecab  
06: preprocess docalign bleualign  
07: bifixer, bicleaner-hardrules  
08: bicleaner-ai  
09: bitextor  
10:  
11:  
12: bitextor, tmxt  


# Running the pipeline
Modify `config.d/10.csd3.sh` to your liking. Especially the paths. Or just
drop in more files with a higher number so they get loaded later. Easy way
to add modifications that don't get tracked in git ;)

Then run the individual steps. There is a `pipeline.sh` file that tries to
schedule the full pipeline for a language pair starting from step 4 by
calling the individual step with `-r`. It should be able to pick up on
jobs that have already finished and jobs that are currently queued/running
but it is not the most robust.

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

Scheduling step 4 to directly pick up after step 3:

```
./04.translate.sh --aftercorr {job-id from step 3 here} wide00006 mt
```

For all possible options, use `--help` or look at `functions.sh`.

One helpful addition is the `--interactive` option, which instead of scheduling
the job will run it in your current terminal, but with all of the environment of
the sbatch run job simulated for you. Useful for debugging/testing.


## Step scripts
Each step consists of a couple of files, for example:

```
03.split-text            : Actual code executed in this step for each batch
03.split-text.sh         : Submission script that sets SLURM parameters and is
                           responsible for finding all files for the job array.                       
```

Most scripts use `generic.slurm` as their "slurm" wrapper. This script functions
a bit like `xargs`, in that it will run the command passed to it for each line
in the batch list that is passed in as it's first argument. If it was started
with --ntasks > 1, it will run ntasks in parallel. (To offload SLURM when there
are many many batches to process, we have our own parallel executor.) By default
it will run the pseudo-jobs in serial (can be controlled with the `TPN` env
variable.)

Additionally, `generic.slurm` creates a job specific `TMPDIR` on the local filesystem of the node and makes sure it cleans up after itself. Note: slurm job specific, not pseudo-job specific. *01.pdf2warc* still creates it's own TMPDIR for singularity so it can clean up after each file.

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
When you "schedule" a step with `--interactive` it will apply this SBATCH override
for you.

Note that the configuration is imported during submission. It uses Slurm to pick
up and transport the ENV to the eventual executed script. This way you can do
manual tweaked submissions by just sourcing the config and calling `sbatch` by
hand, and you can change `config.csd3` without impacting already scheduled jobs.

# Steps

## 01.warc2text
Splits `*.warc` files into `plain_text.gz`, `url.gz`, and `mime.gz`, split by
language. The `text.gz` contains base64-encoded documents. Each document
is already split into lines according to what the HTML dictates as being on a
new line (i.e. `<li>` elements are separate lines, stuff wrapped in `<em>` wont
cause a new line, etc.) PDFs are deposited into a warc archive `pdf.warc.gz`.

Records are filtered by `mt-filter-list.annotated` and `url-filter-list.optimised`. The first filters documents based on tags often found in autmatically translated webpages (mostly Wordpress websites with certain SEO plugins). The second filters a list of known trash websites (e.g. websites that list all possible phone numbers, ip addresses, license plate numbers). `url-filter-list.optimised` is just a more efficient regex, but semantically the same as `url-filter-list.annotated`. Because of the number of records that *warc2text* processes, this silly manual optimisation saves us something like 10% processing time 😅.

Uses [warc2text](https://github.com/bitextor/warc2text), so don't forget to
run `env/setup.sh install warc2text`.

## 01.pdf2warc
**Very much under development**

Step to take that `pdf.warc.gz` and turn it into `pdf-text.warc.gz` which then can be run again through `warc2text`. No real workflow for this exists yet, but it will probably entail symlinking all the resulting `pdf-text.warc.gz` files into a single large collection, and then process that collection from start to end.

Uses [pdfwarc2warc](https://github.com/jelmervdl/pdfwarc2warc) and for that to run, you'll need to build a singularity container of parsr.

### Parsr & singularity
This mostly entails running:

```sh
module load singularity
singularity build parsr.sif docker://axarev/parsr:v1.2.2
```

and then adjusting the path in `02.pdf2warc.sh` to point to your `parsr.sif` file.

## 02.shard
Splits/merges each language's `plain_text.gz`, `url.gz` and `mime.gz` into
shards. For each document (c.f. line) in these files the domain is looked up and
hashed, which decides in which shard the document will end up. Inside that shard
the document is appended to the relative files, which are chopped into about 1GB
max size until a new batch is opened.

Documents are also deduplicated based on their base64-encoded content using `batch_dedupe` in this step. Urls are of duplicate documents are combined in the `url.gz` file in each of the shards: a selection of those urls (currently 4096) are written as a single line (concatenated by spaces) for the deduplicated document.

Sharding is first done in a couple of parallel `giashard` processes. All these batches of shards are then merged into one single batch of shards using `batch_dedupe`.

During this process there are about two copies of all data for a language on disk: the partial shards, and the deduplicated merged shards.

### Manually rerunning a merge step
If you want to rerun *shard 67* of the *wide00016* collection, for *en*, when there were *93* different giashard processes:

```bash
SHARDS_PER_TASK=1 sbatch -J merge-shard-en-wide00016 -a68-68 --time 24:00:00 --cpus-per-task 4 --mem-per-cpu 4096 ./02.giamerge 1-93 en /home/cs-vand1/r/paracrawl/data/ia/wide00016-shards
```

## 03.split-text
Reads the lines from `plain_text.gz` and splits them into multiple lines if
appropriate according to the Moses sentence splitter (the Perl one).

## 04.translate
Translates each line in `sentences.gz` into English according to the parameters
in `translate.sh`. Uses `b64filter` to work on the base64-encoded docs and
`cache` to make translating all the duplications (yes, we don't bother deduping)
a bit less of a hassle.

`04.translate` is basically a simple wrapper around `models/${lang}-en/translate.sh` which does the heavy lifting. Additionally you can have an `env.sh` file in that same language-specific directory to control the scheduling by exporting SBATCH variables. E.g. if your translation system does 32 threads, something like:

```
export SBATCH_CPUS_PER_TASK=32
```

In practice, I have a whole bunch of models in the `models/` directory on CSD3, all of them symlinking one of the four `translate-*.sh` files into their own directory as `translate.sh`. I also generally have multiple models per language pair, and then symlink the one I'm using as `${lang}-en` to make it easier to switch.

## 05.tokenise
This tokenises the English translation. Or in the case of English, the
sentence-split version of plain_text.gz, that is, sentences.gz. Uses the Moses `tokenizer.perl`.

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

## 07.fix
Runs *bifixer* on all of the `aligned-+([0-9]*).gz` files in a batch.

It also runs *bicleaner-hardrules* to make an initial assessment of the sentence pairs. The output is a files with ones and zeros, zero indicating that that sentence pair is not good. We dot this step here to save time in the next step that uses precious GPU core hours. The 08.score step will only look at sentence pairs that have a 1 in the `hardruled.gz` file.

## 08.score
Runs *bicleaner-neural* on all sentence pairs that have a 1 in their `hardruled.gz` file. This step uses GPUs. The scores (for the lines with 1 in `hardruled.gz`) are written to `scored.gz`. If the sentence pair already had a zero, that zero is also copied. So all in all `scored.gz` should have the same number of lines as `fixed.gz`.

## 09.clean
Combines `fixed.gz` with `scored.gz` by making a TSV, effectively. Also removes any lines that match any of the strings in `filtered-terms.txt`. This TSV is saved as `classified.gz`. Finally, a subset of this file, all sentences which make the threshold, will be written to `filtered05.gz` (where `05` depends on `BICLEANER_THRESHOLD`)

## 10.reduce-classified
Just concatenates all classified sentence pair chunks. Not necessary for anything
further down the pipeline, but paracrawl also publishes these files.

**Note** the order of the arguments is now flipped because this step can be
used to combine multiple collections into a single release.

```sh
./10.reduce-classified.sh zh wide00006 wide00015 hieu
```

This generates a file named 
`$DATA/clean/en-zh/en-zh.hieu-wide00006-wide00015.classified.gz`.

## 11.reduce-filtered
Concatenates all filtered sentence pair chunks.

```sh
./11.reduce-filtered.sh zh wide00006 wide000015 hieu
```

The output will be something like 
`$DATA/clean/en-zh/en-zh.hieu-wide00006-wide00015.filtered04.gz`.

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
`$DATA/clean/en-zh.hieu-wide00006-wide00015.{tmx,txt}.gz`.

Note: Step 11 and 12 are not combined because step 11 needs many resources to
sort all sentence pairs. Step 12 consists of just a single-threaded python
script. It would be wasteful to hold up all the resources step 11 needed just
because that python script in step 12 takes such a long time to finish. Hence
step 12 is separate and asks for fewer resources.
