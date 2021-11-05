#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <src-dir> <dst-dir>"
  echo "e.g.: $0 /export/a15/vpanayotov/data/LibriSpeech/dev-clean data/dev-clean"
  exit 1
fi

src=$1
dst=$2

wav_scp=$dst/wav.scp; [[ ! -f "$wav_scp" ]] && echo "Warning: no wav.scp"
trans=$dst/text; [[ ! -f "$trans" ]] && echo "Warning: no text"
utt2spk=$dst/utt2spk; [[ ! -f "$utt2spk" ]] && echo "Warning: no utt2spk"
spk2gender=$dst/spk2gender; [[ ! -f "$spk2gender" ]] && echo "Warning: no spk2gender"
utt2dur=$dst/utt2dur;


#while read line; do
#  a=($line)
#  dir=$(echo ${a[1]} | tr '_' '/')
#  flac_file="$src/$dir/${a[0]}.flac"
#  dur=$(ffmpeg -i $flac_file 2>&1 | grep Duration | cut -d ' ' -f 4 | sed s/,// | cut -d ':' -f 3)
#  if [ $(echo $dur'>'$maxutt | bc -l) -eq 1 ]; then
#    echo $flac_file $dur
#    find $dst -type f -maxdepth 1 -exec sh -c "sed -i '/${a[0]}/d' {}" \; 
#  fi
#done < $utt2spk
#
# sort 
cat $wav_scp    | sort > tmp
cp tmp $wav_scp
cat $trans      | sort > tmp
cp tmp $trans
cat $utt2spk    | sort > tmp
cp tmp $utt2spk
cat $spk2gender | sort > tmp
cp tmp $spk2gender
rm tmp


spk2utt=$dst/spk2utt
utils/utt2spk_to_spk2utt.pl <$utt2spk >$spk2utt || exit 1

ntrans=$(wc -l <$trans)
nutt2spk=$(wc -l <$utt2spk)
! [ "$ntrans" -eq "$nutt2spk" ] && \
  echo "Inconsistent #transcripts($ntrans) and #utt2spk($nutt2spk)" && exit 1;

utils/data/get_utt2dur.sh $dst 1>&2 || exit 1

utils/validate_data_dir.sh --no-feats $dst || exit 1;

echo "$0: successfully confirmed data in $dst"

exit 0
