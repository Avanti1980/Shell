#!/usr/bin/env bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

source list-select.sh

ext="m4a|aac|ac3|mp3|mp2|flac|ape|wav"
list_file $ext
file=$(select_file $ext)

ffmpeg -hide_banner -i "$file" -lavfi showspectrumpic=s=960x540:orientation=1 "$file.png"
