#!/bin/bash

#words="./test.txt"
words="./data/lang/words.txt"
last=`tail -n 1 $words | cut -f 2 -d " "`
echo $last
#last=0

for part in $@; do
  while read line; do
    line=`echo $line | sed 's/[^가-힣 ]//g'`
    echo $line
    IFS=' ' read -r -a word <<< $line
    for now in "${word[@]}"; do
      if ! grep -q $now $words; then
        #echo $now
        echo -n "$now " >> $words
        last=`echo $last + 1 | bc`
        echo $last >> $words
      fi
    done
  done < $part
done
