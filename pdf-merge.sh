#!/usr/bin/env bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

source list-select.sh

command="pdftk"
while true; do

    ext="pdf|PDF"
    list_file $ext
    file=$(select_file $ext)

    command="$command \"$file\""

    echo '继续添加文件 [Y/n]:'
    read add_more

    if [ "$add_more" == 'y' ] || [ -z "$add_more" ]; then
        continue
    fi

    if [ $add_more == 'n' ]; then
        break
    fi
done

echo "请输入合并后的文件名(不需要扩展名):"
read output_name

command="$command cat output \"$output_name.pdf\""
eval $command
