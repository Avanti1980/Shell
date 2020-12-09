#!/usr/bin/env bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

file_list=$(find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(mp4|mkv|ts)")

for file in $file_list; do
    rar a -m0 -v498m "$(echo $file | sed 's/\(.*\)\..*/\1/g')" "$file"
done
