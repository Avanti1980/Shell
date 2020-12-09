#!/usr/bin/env bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

for file in $(find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(m4a|aac|ac3|mp3|mp2|flac|ape|wav)"); do
    echo 正在处理 $file
    ffmpeg -hide_banner -i "$file" -lavfi showspectrumpic=s=960x540:orientation=1 "$file.png"
done
