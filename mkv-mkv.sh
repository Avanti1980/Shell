#!/usr/bin/env bash

num=0
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
file_list=$(find ./ -regextype posix-extended -regex ".*\.(mkv|MKV)")
for file in $file_list; do
    ((num++))
    file_name=$(echo $file | cut -d / -f 2)
    cmd="ffmpeg -i $file_name -map 0:0 -map 0:1 -c copy 第$(echo $file_name | sed 's/.*Ep\(.*\)\.HDTV.*/\1/g')集.mkv"
    echo $cmd
    eval $cmd
done
