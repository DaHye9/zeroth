#!/bin/sh

if [[ "$#" -ne 1 ]]; then
  echo Usage: $0 scrip/trans
  exit
fi

for i in *
do
    if [ -d $i ]; then
        cd $i
        for j in *
        do
            cd $j
            for k in *
            do
                cd $k
		
		now=${i}_${j}_${k}
		now_file=$now.$1.txt.prev
                if [ ! -e $now_file ]; then
                    touch $now_file
		else cat /dev/null > $now_file
		fi

		for file in ./*
		do
		    if [[ $file == *.txt ]] && [[ $file != *.trans.txt* ]] && [[ $file != *.scrip.txt* ]]; then
			cat $file >> $now_file
			echo -e " " >> $now_file
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
