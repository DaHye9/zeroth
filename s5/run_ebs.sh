#!/bin/bash
#
# Based mostly on the WSJ/Librispeech recipe. The training database is #####,
#
# Copyright  2017  Atlas Guide (Author : Lucas Jo)
#            2017  Gridspace Inc. (Author: Wonkyum Lee)
#
# Apache 2.0
#

# Check list before start
# 1. locale setup
# 2. pre-installed package: awscli, Morfessor-2.0.1, flac, sox, same cuda library, unzip
# 3. pre-install or symbolic link for easy going: rirs_noises.zip (takes pretty long time)
# 4. parameters: nCPU, num_jobs_initial, num_jobs_final, --max-noises-per-minute

data=./DATA
nCPU=16

. ./cmd.sh
. ./path.sh

# you might not want to do this for interactive shells.
set -e

startTime=$(date +'%F-%H-%M')
echo "started at" $startTime

# format the data as Kaldi data directories
#train_data_01 test_data_01
d=0
if [ $d == 1 ]; then
for part in train_ebs; do
	# use underscore-separated names in data directories.
	local/ebs_data_prep.sh $data/$part data/$(echo $part | sed s/-/_/g)
	local/confirm_data.sh $data/$part data/$(echo $part | sed s/-/_/g)
done
fi
d=0
if [ $d == 1 ]; then
for part in train_data_01 test_data_01; do
	# use underscore-separated names in data directories.
	local/data_prep.sh $data/$part data/$(echo $part | sed s/-/_/g)
	local/confirm_data.sh $data/$part data/$(echo $part | sed s/-/_/g)
done
fi


echo "######data_prep done"

# update segmentation of transcripts
d=0
if [ $d == 1 ]; then
for part in train_ebs train_data_01 test_data_01 valid_ebs; do
	local/updateSegmentation.sh data/$part data/local/lm
done
fi

# prepare dictionary and language model 
d=0
if [ $d == 1 ]; then
local/prepare_dict.sh data/local/lm data/local/dict

utils/prepare_lang.sh data/local/dict_nosp \
	"<UNK>" data/local/lang_tmp data/lang

local/format_lms.sh --src-dir data/lang data/local/lm
fi

# Create ConstArpaLm format language model for full 3-gram and 4-gram LMs
# it takes long time and do this again after computing silence prob.
# you can do comment out here this time

#utils/build_const_arpa_lm.sh data/local/lm/zeroth.lm.tg.arpa.gz \
#	data/lang_nosp data/lang_nosp_test_tglarge
#utils/build_const_arpa_lm.sh data/local/lm/zeroth.lm.fg.arpa.gz \
#	  data/lang_nosp data/lang_nosp_test_fglarge

# Feature extraction (MFCC)
d=0
if [ $d == 1 ]; then
mfccdir=mfcc
#hostInAtlas="ares hephaestus jupiter neptune"
#if [[ ! -z $(echo $hostInAtlas | grep -o $(hostname -f)) ]]; then
#  mfcc=$(basename mfccdir) # in case was absolute pathname (unlikely), get basename.
#  utils/create_split_dir.pl /mnt/{ares,hephaestus,jupiter,neptune}/$USER/kaldi-data/zeroth/s5/$mfcc/storage \
#    $mfccdir/storage
#fi
for part in train_data_01 test_data_01 train_ebs valid_ebs; do
	steps/make_mfcc.sh --cmd "$train_cmd" --nj $nCPU data/$part exp/make_mfcc/$part $mfccdir
	steps/compute_cmvn_stats.sh data/$part exp/make_mfcc/$part $mfccdir
done
fi


## Combine data sets and split trainset and testset
#d=1
#if [ $d == 1 ]; then
#utils/combine_data.sh data/merged data/train_data_01 data/test_data_01 data/train_ebs data/valid_ebs
#local/split_dataset.sh --ratio 20 data/merged data/trainset_01 data/testset_01
#local/split_dataset.sh --ratio 20 data/train_data_02 data/trainset_02 data/testset_02
#local/split_dataset.sh --ratio 20 data/train_data_03 data/trainset_03 data/testset_03
#fi
#
## Merge trainsets and testsets
#d=1
#if [ $d == 1 ]; then
#utils/combine_data.sh data/train_clean data/trainset_01 data/trainset_02 data/trainset_03
#utils/combine_data.sh data/test_clean  data/testset_01 data/testset_02 data/testset_03
#fi

# Make some small data subsets for early system-build stages.
d=0
if [ $d == 1 ]; then
#utils/subset_data_dir.sh --shortest data/train_ebs 1500000 data/train_ebs_short
#utils/subset_data_dir.sh data/train_ebs_short 60000 data/train_ebs_60kshort
utils/subset_data_dir.sh data/train_ebs 60000 data/train_ebs_60k
fi

d=0
if [ $d == 1 ]; then
echo "#### Monophone Training ###########"
# train a monophone system & align
steps/train_mono.sh --nj 8 --cmd "$train_cmd" \
	data/train_data_01 data/lang exp/mono_zeroth_all
fi

echo "#### Triphone Training, delta + delta-delta ###########"
# train a first delta + delta-delta triphone system on a subset of 5000 utterancesa
# number of maximum pdf, gaussian (under/over fitting)
#  recognition result 
d=0
if [ $d == 1 ]; then
#steps/align_si.sh --nj 8 --cmd "$train_cmd" \
#  data/train_data_01 data/lang exp/mono_zeroth_all exp/mono_ali_zeroth_all
steps/train_deltas.sh --cmd "$train_cmd" \
    30 5000 data/train_data_01 data/lang exp/mono_ali_zeroth_all exp/tri1_zeroth_all
steps/align_si.sh --nj 8 --cmd "$train_cmd" \
  data/train_ebs_60kshort data/lang exp/tri1_zeroth_all exp/tri1_ali_ebs_60kshort
steps/train_deltas.sh --cmd "$train_cmd" \
    100 10000 data/train_ebs_60kshort data/lang exp/tri1_ali_ebs_60kshort exp/tri2_ebs_60kshort
steps/align_si.sh --nj 8 --cmd "$train_cmd" \
  data/train_ebs_60k data/lang exp/tri2_ebs_60kshort exp/tri2_ali_ebs_60k
steps/train_deltas.sh --cmd "$train_cmd" \
    3000 10000 data/train_ebs_60k data/lang exp/tri2_ali_ebs_60k exp/tri3_ebs_60k
fi

d=0
echo "#### Triphone Training, LDA+MLLT ###########"
# train an LDA+MLLT system.
if [ $d == 1 ]; then
#steps/align_si.sh --nj 8 --cmd "$train_cmd" \
#  data/train_ebs_short data/lang exp/tri3_ebs_60k exp/tri3_ali_ebs_short
#steps/train_lda_mllt.sh --cmd "$train_cmd" \
#   --splice-opts "--left-context=3 --right-context=3" 30 60000 \
#   data/train_ebs_short data/lang exp/tri3_ali_ebs_short exp/tri4_ebs_short

# Align a 10k utts subset using the tri2b model
steps/align_si.sh  --nj 8 --cmd "$train_cmd" --use-graphs true \
  data/train_ebs_short data/lang exp/tri4_ebs_short exp/tri4_ali_ebs_short

echo "#### Triphone Training, LDA+MLLT+SAT ###########"
# Train tri3b, which is LDA+MLLT+SAT on 10k utts
#steps/train_sat.sh --cmd "$train_cmd" 3000 25000 \
steps/train_sat.sh --cmd "$train_cmd" 4200 60000 \
  data/train_ebs_short data/lang exp/tri4_ali_ebs_short exp/tri5b
fi

d=0
if [ $d == 1 ]; then
utils/dict_dir_add_pronprobs.sh --max-normalize true \
      data/local/dict_nosp \
        exp/tri5b/pron_counts_nowb.txt exp/tri5b/sil_counts_nowb.txt \
          exp/tri5b/pron_bigram_counts_nowb.txt data/local/dict

utils/prepare_lang.sh data/local/dict \
      "<UNK>" data/local/lang_tmp data/lang
fi

d=0
if [ $d == 1 ]; then
local/format_lms.sh --src-dir data/lang data/local/lm

utils/build_const_arpa_lm.sh \
      data/local/lm/zeroth.lm.tg.arpa.gz data/lang data/lang_test_tglarge
utils/build_const_arpa_lm.sh \
      data/local/lm/zeroth.lm.fg.arpa.gz data/lang data/lang_test_fglarge
fi


# align the entire train_clean using the tri3b model
d=0
if [ $d == 1 ]; then
steps/align_si.sh  --nj 8 --cmd "$train_cmd" --use-graphs true \
  data/train_ebs_short data/lang exp/tri5b exp/tri5b_ali_si_ebs_short

steps/align_fmllr.sh --nj 8 --cmd "$train_cmd" \
  data/train_ebs_short data/lang exp/tri5b_ali_si_ebs_short exp/tri5b_ali_fmllr_ebs_short

steps/train_sat.sh --cmd "$train_cmd" 4200 60000 \
  data/train_ebs_short data/lang exp/tri5b_ali_fmllr_ebs_short exp/tri6b

# decode using the tri4b model with pronunciation and silence probabilities
utils/mkgraph.sh \
  data/lang_test_tgsmall exp/tri6b exp/tri6b/graph_tgsmall

fi

d=1
if [ $d == 1 ]; then
# the size is properly set?
#utils/subset_data_dir.sh data/valid_ebs 2000 data/valid_ebs_test_2000
echo 'subset done'
for test in valid_ebs_test_2000; do
  nspk=$(wc -l <data/${test}/spk2utt)
  steps/decode_fmllr.sh --nj $nspk --cmd "$decode_cmd" \
    exp/tri6b/graph_tgsmall data/$test \
    exp/tri6b/decode_tgsmall_$test
  #steps/lmrescore.sh --cmd "$decode_cmd" data/lang_test_{tgsmall,tgmed} \
  #  data/$test exp/tri4b/decode_{tgsmall,tgmed}_$test
  steps/lmrescore_const_arpa.sh \
    --cmd "$decode_cmd" data/lang_test_{tgsmall,tglarge} \
    data/$test exp/tri6b/decode_{tgsmall,tglarge}_$test
  steps/lmrescore_const_arpa.sh \
    --cmd "$decode_cmd" data/lang_test_{tgsmall,fgmed} \
    data/$test exp/tri6b/decode_{tgsmall,fgmed}_$test
done
# align train_clean_100 using the tri4b model
steps/align_fmllr.sh --nj $nCPU --cmd "$train_cmd" \
	  data/train_ebs_short data/lang exp/tri6b exp/tri6b_ali_ebs_short
finishTime=$(date +'%F-%H-%M')
fi

d=0
if [ $d == 1 ]; then
# Now we compute the pronunciation and silence probabilities from training data,
# and re-create the lang directory.
# silence transition probability ...
steps/get_prons.sh --cmd "$train_cmd" \
      data/train_ebs_short data/lang_nosp exp/tri6b
fi


echo "GMM trainig is finished at" $finishTime

## online chain recipe using only clean data set
d=0
if [ $d == 1 ]; then
echo "#### online chain training  ###########"
## check point: sudo nvidia-smi --compute-mode=3 if you have multiple GPU's
#local/chain/run_tdnn_1a.sh
#local/chain/run_tdnn_1b.sh
#local/chain/multi_condition/run_tdnn_lstm_1e.sh --nj $nCPU
local/chain/multi_condition/run_tdnn_1n.sh --nj $nCPU 
#local/chain/run_tdnn_opgru_1c.sh --nj $nCPU

fi
finishTime=$(date +'%F-%H-%M')
echo "DNN trainig is finished at" $finishTime
echo "started at" $startTime
echo "finished at" $finishTime
exit 0;

