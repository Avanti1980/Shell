#!/usr/bin/env bash

# 批量处理某一目录下所有视频文件名 删除前两个字符

num=0

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

file_list=$(find *.flv)
file_num=$(echo "$file_list" | grep -o 'flv' | wc -l)
((file_num++))
file_index=$(seq -s. -w $file_num)

echo "文件信息如下: " >info.txt

for file in $file_list; do
    ((num++))

    index=$(echo "$file_index" | cut -d . -f $num)

    file_name=$(echo $file | cut -d / -f 2)

    file_no_ext_name=${file_name%.*}
    file_ext_name=${file_name##*.}

    audio_bit_rate=$(mediainfo --Inform="Audio;%BitRate%" "$file_name")
    video_bit_rate=$(mediainfo --Inform="Video;%BitRate%" "$file_name")

    file_new_name=${file_name:2}
    video_bit_rate=$(expr substr "$video_bit_rate" 1 4)

    echo $index. [视频码率 $video_bit_rate] [显示码率 "    "] [未被二压 " "] [$file_no_ext_name] >>info.txt

    #echo $index. [音频码率 $audio_bit_rate] [视频码率 $video_bit_rate] [显示码率 "    "] [未被二压 " "] [$file_no_ext_name] >> info.txt

done

IFS=$SAVEIFS
