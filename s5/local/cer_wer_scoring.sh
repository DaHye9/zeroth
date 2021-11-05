#!/bin/bash


scoredir=./steps/scoring
datadir=./data/valid_ebs_science
modeldir=./test/models/korean/ebs_model_v1
#modeldir=./exp/chain_rvb/tdnn1n_rvb/tree_a_ebs
decodedir=$1
#decodedir=./exp/chain_rvb/tdnn1n_rvb_online/decode_fglarge_test_valid_ebs_science_school_ebsonly

#$scoredir/score_kaldi_wer.sh --cmd run.pl $datadir $modeldir $decodedir || exit
$scoredir/score_kaldi_cer.sh --cmd run.pl $datadir $modeldir $decodedir || exit
