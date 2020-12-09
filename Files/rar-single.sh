#!/usr/bin/env bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

source list-select.sh

ext="mp4|mkv|ts"
list_file $ext
file=$(select_file $ext)

rar a -m0 -v998m "$(echo $file | sed 's/\(.*\)\..*/\1/g')" "$file"
