#!/usr/bin/env bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

command="gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$1-full.pdf"

num=0
for file in $(ls | grep $1); do
    command="$command $file"
done
echo $command
eval $command
# gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="${paper_name%.pdf}-merge.pdf" "$paper_name" "$supp_name"
