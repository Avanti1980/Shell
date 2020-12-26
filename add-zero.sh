#!/usr/bin/env bash

# 文件名中的 第[1-9]集 -> 第0[1-9]集

num=0
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
file_list=$(ls)
for file in $file_list; do
    file_name=$(echo $file | cut -d / -f 2)
    file_name_target=$(echo $file_name | sed 's/第\([1-9]\)集/第0\1集/g')
    if [ "$file_name" != "$file_name_target" ]; then
        mv "$file_name" "$file_name_target"
    fi
done
