#!/usr/bin/env bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

file_list=$(baidupcs ls 徐梵溪/$1 | grep "第")
for file in $file_list; do
    original_name=$(echo $file | sed "s/.*  第\(.*\)集.mp4.*/第\1集.mp4/g")
    target_name=$(echo $file | sed "s/.*  第\(.*\)集.mp4.*/第\1集.mp4.xufanxi/g")
    cmd="baidupcs mv 徐梵溪/$1/$original_name 徐梵溪/$1/$target_name"
    echo $cmd
    eval $cmd
done
