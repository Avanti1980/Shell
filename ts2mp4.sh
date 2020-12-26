#!/usr/bin/env bash

num=0
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
file_list=$(find ./ -regextype posix-extended -regex ".*\.(ts|TS)")
for file in $file_list; do
    ((num++))
    file_name=$(echo $file | cut -d / -f 2)
    ffmpeg -i "$file_name" -c copy "$(echo $file_name | sed 's/\(.*\)\..*/\1/g')".mp4
done
