#!/bin/bash

if [ "$UID" -ne 0 ]; then exec sudo bash "$0" "$@"; exit; fi

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <data_dir_name> <scrip/trans> <json 1/0> from this loc"
    echo "e.g.: $0 train_ebs"
    exit 1
fi


json=$3
#Getting script file list

trans_list="trans_file_list.txt"

if [ ! -e $trans_list ]; then
    touch $trans_list
else cat /dev/null > $trans_list
fi

echo $1
find $1 -name "*.$2.txt.prev" >> $trans_list

#Preprocessing transcript files with script file list

#Making audo_info by json data
cat $trans_list | while read line; do
    echo $line
    next_line=$(echo "$line" | sed 's/.prev//g')
    echo $next_line
    if [ ! -e $next_line ]; then
      touch $next_line; fi
    LANG=C sed -r -f sed_pattern.file $line > $next_line
    LANG=C sed -ri 's/[^\?\!\.\_ 0-9A-Z가-힣ㄱ-ㅎㅏ-ㅣ]//g' $next_line
    LANG=C sed -i 's/\///g' $next_line
    LANG=C sed -i '/b\/\n/D' $next_line
    LANG=C sed -i 's/  / /g' $next_line
    #echo $del
    #awk '{ print $1.flac }' "$del" | xargs rm
    if [[ $json -eq "1" ]]; then   
	d_list=(`echo $line | tr "/" "\n"`)
	speaker_id=${d_list[3]}
	script_id=${d_list[1]}_${d_list[2]}
	script_dir=${d_list[1]}/${d_list[2]}
	data_set=${d_list[0]}
	echo $json
	now_json=/home/ubuntu/ebs_speech_data/KlecSpeech/$data_set/$script_dir/$speaker_id/$speaker_id.json
	echo $now_json
	gen=$(./get_gender.pl ${now_json})
	echo "${speaker_id}|${speaker_id}|${gen}|${script_id}|${data_set}" >> ./AUDIO_INFO
    fi
done
