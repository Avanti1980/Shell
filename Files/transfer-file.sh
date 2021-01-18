#!/usr/bin/env bash

# usage: transfer-file.sh host ip password, e.g., transfer-file.sh avanti 192.168.1.101 xixi013579

read -p "1. 文件(默认); 2. 文件夹; 请选择传输的目标: " select_index

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

if [ "$select_index" != "2" ]; then
    file_num=$(ls -1 -F | grep -v [/$] | wc -l)
    echo "当前目录下共有$file_num个文件:"
    num=0

    file_list=$(ls -1 -F | grep -v [/$])
    for line in $file_list; do
        ((num++))
        echo "$num. $line"
    done

    read -p "请选择(序号): " select_index
    num=0
    for line in $file_list; do
        ((num++))
        if [ "$select_index" == "$num" ]; then
            dot_num=$(echo "$line" | grep -o "\." | wc -l)
            ((dot_num++))
            file_ext_name=$(echo "$line" | cut -d . -f $dot_num)

            read -p "1. ~/Videos(默认); 2. ~/; 请选择传输的位置: " select_index

            if [ "$select_index" == "2" ]; then
                sshpass -p $3 scp "$line" $1@$2:~/
            else
                sshpass -p $3 scp "$line" $1@$2:~/Videos
            fi
            break
        fi
    done
else
    file_num=$(ls -F | grep [/$] | wc -l)
    echo "当前目录下共有$file_num个文件夹:"
    num=0

    file_list=$(ls -F | grep [/$])
    for line in $file_list; do
        ((num++))
        echo "$num. $line"
    done

    read -p "请选择(序号): " select_index
    num=0
    for line in $file_list; do
        ((num++))
        if [ "$select_index" == "$num" ]; then
            sshpass -p $3 scp -r "$line" $1@$2:~/
            break
        fi
    done
fi
