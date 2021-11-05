#!/bin/bash
for now in $@; do
  echo $now
  sed -i "/$now/d" data/train_ebs/wav.scp
  sed -i "/$now/d" data/train_ebs/spk2utt
  sed -i "/$now/d" data/train_ebs/utt2spk
  sed -i "/$now/d" data/train_ebs/text
done
