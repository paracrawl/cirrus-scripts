MODEL_IMPL=translate_moses
MODEL_ARCH=cpu

model_is_en () {
    MODEL=${MODELS}/prompsit-system/moses.BLEUALIGN_MOSES_IS_EN.is-en
    MOSES_BIN=$MOSES/bin/moses
    MOSES_INI=moses.ini
    TRUECASE_MODEL=truecaser.is
}

model_nb_en () {
    MODEL=${MODELS}/prompsit-system/moses.BLEUALIGN_MOSES_NB_EN.nb-en
    MOSES_BIN=$MOSES/bin/moses
    MOSES_INI=moses.ini
    TRUECASE_MODEL=truecaser.nb
}

model_nn_en () {
    MODEL=${MODELS}/prompsit-system/moses.BLEUALIGN_MOSES_NN_EN.nn-en
    MOSES_BIN=$MOSES/bin/moses
    MOSES_INI=moses.ini
    TRUECASE_MODEL=truecaser.nn
}

model_no_en () {
	# Treat the generic no as nb
	model_nb_en
}

model_bg_en () {
    MODEL=${MODELS}/phi-system/fast-bg-en
    TRUECASE_MODEL=truecase-model.bg
}

model_cs_en () {
    MODEL=${MODELS}/phi-system/fast-cs-en
    TRUECASE_MODEL=truecase-model.cs
}

model_da_en () {
    MODEL=${MODELS}/phi-system/fast-da-en
    TRUECASE_MODEL=truecase-model.da
}

model_de_en () {
    MODEL=${MODELS}/phi-system/fast-de-en
    TRUECASE_MODEL=truecase-model.de
}

model_el_en () {
    MODEL=${MODELS}/phi-system/fast-el-en
    TRUECASE_MODEL=truecase-model.el
}

#model_es_en () {
#    MODEL=${MODELS}/phi-system/fast-es-en
#    TRUECASE_MODEL=truecase-model.es
#}

# Experiment: Bergamot marian
model_es_en () {
    MODEL_IMPL=translate_marian_cpu
    MODEL=${MODELS}/bergamot/esen.student.tiny11
}

#model_et_en () {
#    MODEL=${MODELS}/phi-system/fast-et-en
#    TRUECASE_MODEL=truecase-model.et
#}

# Experiment: Bergamot marian
model_et_en () {
    MODEL_IMPL=translate_marian_cpu
    MODEL=${MODELS}/bergamot/eten.student.tiny11
}

model_fi_en () {
    MODEL=${MODELS}/phi-system/fast-fi-en
    TRUECASE_MODEL=truecase-model.fi
}

model_fr_en () {
    MODEL=${MODELS}/phi-system/fast-fr-en
    TRUECASE_MODEL=truecase-model.fr
}

model_ga_en () {
    MODEL=${MODELS}/phi-system/fast-ga-en
    TRUECASE_MODEL=truecase-model.ga
}

model_hr_en () {
    MODEL=${MODELS}/phi-system/fast-hr-en
    TRUECASE_MODEL=truecase-model.hr
}

model_hu_en () {
    MODEL=${MODELS}/phi-system/fast-hu-en
    TRUECASE_MODEL=truecase-model.hu
}

model_it_en () {
    MODEL=${MODELS}/phi-system/fast-it-en
    TRUECASE_MODEL=truecase-model.it
}

model_lt_en () {
    MODEL=${MODELS}/phi-system/fast-lt-en
    TRUECASE_MODEL=truecase-model.lt
}

model_lv_en () {
    MODEL=${MODELS}/phi-system/fast-lv-en
    TRUECASE_MODEL=truecase-model.lv
}

model_mt_en () {
    MODEL=${MODELS}/phi-system/fast-mt-en
    TRUECASE_MODEL=truecase-model.mt
}

model_nl_en () {
    MODEL=${MODELS}/phi-system/fast-nl-en
    TRUECASE_MODEL=truecase-model.nl
}

model_pl_en () {
    MODEL=${MODELS}/phi-system/fast-pl-en
    TRUECASE_MODEL=truecase-model.pl
}

model_pt_en () {
    MODEL=${MODELS}/phi-system/fast-pt-en
    TRUECASE_MODEL=truecase-model.pt
}

model_ro_en () {
    MODEL=${MODELS}/phi-system/fast-ro-en
    TRUECASE_MODEL=truecase-model.ro
}

model_ru_en () {
    MODEL=${MODELS}/phi-system/fast-ru-en
    TRUECASE_MODEL=truecase-model.ru
}

model_sk_en () {
    MODEL=${MODELS}/phi-system/fast-sk-en
    TRUECASE_MODEL=truecase-model.sk
}

model_sl_en () {
    MODEL=${MODELS}/phi-system/fast-sl-en
    TRUECASE_MODEL=truecase-model.sl
}

model_sv_en () {
    MODEL=${MODELS}/phi-system/fast-sv-en
    TRUECASE_MODEL=truecase-model.sv
}

model_ps_en () {
    MODEL=/home/cs-vand1/rds/rds-t2-cs119/romang/psen
    TRUECASE_MODEL=tc.ps
    MODEL_IMPL=translate_marian
    MODEL_ARCH=gpu
}

model_gl_es() {
    MODEL=gl-es
    MODEL_IMPL=translate_apertium
    MODEL_ARCH=cpu
}

model_ca_es() {
    MODEL=cat-spa
    MODEL_IMPL=translate_apertium
    MODEL_ARCH=cpu
}

model_eu_es() {
    MODEL=eu-es
    MODEL_IMPL=translate_apertium
    MODEL_ARCH=cpu
}

model_oc_es() {
    MODEL=oc-es
    MODEL_IMPL=translate_apertium
    MODEL_ARCH=cpu
}

model_fa_en() {
    MODEL_IMPL=translate_extern_gpu
    MODEL_ARCH=gpu
	export TRANSLATE_SCRIPT="/home/cs-vand1/src/cirrus-scripts/translate_fa_en.sh fa"

    # Hard override full-on I dont care mode
    export SLURM_ACCOUNT=t2-cs119-gpu
    export SLURM_PARTITION=pascal
    export TASKS_PER_BATCH=1
}

model_ha_en() {
	MODEL_IMPL=translate_extern_cpu
	MODEL_ARCH=cpu
	export TRANSLATE_SCRIPT=/rds/project/t2_vol4/rds-t2-cs119/jhelcl/gourmet/baselines/ha-en/scripts/translate.sh
}

model_ig_en() {
	MODEL_IMPL=translate_extern_cpu
	MODEL_ARCH=cpu
	export TRANSLATE_SCRIPT=/rds/project/t2_vol4/rds-t2-cs119/jhelcl/gourmet/baselines/ig-en/scripts/translate.sh
}

model_zh_en() {
	MODEL_IMPL=translate_extern_cpu
	MODEL_ARCH=cpu
	export TRANSLATE_FOLD_COLUMN=100
	export TRANSLATE_SCRIPT=$SCRIPTS/translate_zh_en.sh
}

model_ko_en() {
	MODEL_IMPL=translate_extern_cpu
	MODEL_ARCH=cpu
	export TRANSLATE_FOLD_COLUMN=100
	export TRANSLATE_SCRIPT=$SCRIPTS/translate_ko_en.sh
}

translate_extern_gpu() {
	shift # consume language
	$TRANSLATE_SCRIPT "$@"
}

translate_extern_cpu() {
	shift # Consume language
	$TRANSLATE_SCRIPT \
		--quiet-translation \
		--cpu-threads $THREADS \
		"$@"
}

translate_moses () {
    local SLANG="$1"
    shift

    pushd . > /dev/null
    cd "$MODEL"
    $MOSES/scripts/tokenizer/tokenizer.perl -a -q -l $SLANG | \
        $MOSES/scripts/recaser/truecase.perl --model $TRUECASE_MODEL | \
        $MOSES_BIN -v 0 $MOSES_ARGS -f $MOSES_INI | \
        $MOSES/scripts/recaser/detruecase.perl | \
        $MOSES/scripts/tokenizer/detokenizer.perl -q
    popd > /dev/null
}

translate_marian() {
    local SLANG="$1"
    shift

    pushd . > /dev/null
    cd "$MODEL"
    perl $MOSES/scripts/tokenizer/tokenizer.perl -l $SLANG -q \
        | perl $MOSES/scripts/recaser/truecase.perl -model $TRUECASE_MODEL \
        | python3 $BPE/apply_bpe.py -c $MODEL/bpe.$SLANG \
        | $MARIAN/marian-decoder -c $MODEL/config.yml "$@" \
        | perl -pe 's/@@ //g' \
        | $MOSES/scripts/recaser/detruecase.perl \
        | perl $MOSES/scripts/tokenizer/detokenizer.perl -l $SLANG -q
    popd > /dev/null
}

translate_marian_cpu() {
    local SLANG="$1"
    shift

    pushd . > /dev/null
    cd "$MODEL"
    ../marian-dev-intgemm/marian-decoder -c $MODEL/config.yml \
        --quiet --quiet-translation \
        --cpu-threads 16 \
        --max-length-crop
    popd > /dev/null
}

readlines () {
    local N="$1"
    local line
    local rc="1"

    # Read at most N lines
    for i in $(seq 1 $N)
    do
        # Try reading a single line
        read line
        if [ $? -eq 0 ]
        then
            # Output line
            echo $line
            rc="0"
        else
            break
        fi
    done

    # Return 1 if no lines where read
    return $rc
}

export -f readlines

translate_apertium() {
    # Apertium messes up lines when encountering utf-8 nbsp. It
    # also has trouble with "^$", introducing a full stop and
    # skipping the line break altogether.
    # Note: eu has some oddity where it break on @ sometimes.
    # Adding `| tr '@' '.'` helps with that.
    sed "s/\xc2\xad/ /g" \
        | sed "s/\x00//g" \
        | sed 's/\\^\\$//g' \
        | $APERTIUM/bin/apertium-destxt -i \
        | $APERTIUM/bin/apertium -f none -u $MODEL \
        | $APERTIUM/bin/apertium-retxt
}

chunk_translate_apertium() {
    while chunk=$(readlines 1000); do
        translate_apertium "$@" <<< "$chunk"
    done
}
