#!/bin/sh

for i in *; do
if [ -d $i ]; then
        cd $i
        for j in *; do
	    cd $j
            for k in *; do
                cd $k
		
		now=${i}_${j}_${k}
		echo $now
		now_file=$now.trans.txt.prev
		now_scrip=$now.scrip.txt
                if [ ! -e $now_file ]; then
                    touch $now_file
		else cat /dev/null > $now_file
		fi

		for file in ./*
		do
		    file_name=${file:2:6}
		    new_flac_name=${i}_${j}_${k}_${file_name}
		    echo $file
		    if [[ $file == *.wav ]] && [[ ! -e ./${new_flac_name}.flac ]]; then
		        ffmpeg -i ${file} ${new_flac_name}.flac
		    elif [[ $file == *.txt ]] && [[ $file != *.trans* ]] && [[ $file != *.scrip* ]] && [[ -e ${new_flac_name}.flac ]]; then
#			sed -i 's/^\.//g' $file
#			echo -n $new_flac_name >> $now_file
#			echo -n " " >> $now_file
#			cat $file >> $now_file
			cat $file >> $now_scrip
			echo -n " " >> $now_scrip
#			echo -e "\n" >> $now_file
		    elif [[ $file == *.zip ]]; then
			rm $file
		    fi
		done
                cd ../
            done
        cd ../
        done
    cd ../
fi
done
cd ../
