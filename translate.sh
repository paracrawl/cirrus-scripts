translate_is () {
    cd ${MODELS}/prompsit-system/moses.BLEUALIGN_MOSES_IS_EN.is-en
    MOSES_BIN=$MOSES/bin/moses
    MOSES_INI=moses.ini
    TRUECASE_MODEL=truecaser.is
}

translate_nb () {
    cd ${MODELS}/prompsit-system/moses.BLEUALIGN_MOSES_IS_EN.nb-en
    MOSES_BIN=$MOSES/bin/moses
    MOSES_INI=moses.ini
    TRUECASE_MODEL=truecaser.nb
}

translate_nn () {
    cd ${MODELS}/prompsit-system/moses.BLEUALIGN_MOSES_IS_EN.nn-en
    MOSES_BIN=$MOSES/bin/moses
    MOSES_INI=moses.ini
    TRUECASE_MODEL=truecaser.nn
}

translate_mt () {
    cd ${MODELS}/phi-system/fast-mt-en
    TRUECASE_MODEL=truecase-model.mt
}

translate_fr () {
    cd ${MODELS}/phi-system/fast-fr-en
    TRUECASE_MODEL=truecase-model.fr
}

translate_de () {
    cd ${MODELS}/phi-system/fast-de-en
    TRUECASE_MODEL=truecase-model.de
}

translate_nl () {
    cd ${MODELS}/phi-system/fast-nl-en
    TRUECASE_MODEL=truecase-monll.de
}

translate () {
    SLANG="$1"
    eval translate_"$SLANG"
    $MOSES/scripts/tokenizer/tokenizer.perl -a -q -l $SLANG | \
        $MOSES/scripts/recaser/truecase.perl --model $TRUECASE_MODEL | \
        $MODELS/phi-system/trim_lines.py 100 | \
        $MOSES_BIN -v 0 $MOSES_ARGS -f $MOSES_INI | \
        $MOSES/scripts/recaser/detruecase.perl | \
        $MOSES/scripts/tokenizer/detokenizer.perl -q | \
        sed 's/^< P >$/<P>/'
}

translate "$1"
