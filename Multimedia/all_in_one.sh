SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
source my_function.sh
arr_function=(视频压制 音频处理 格式转换 合并文件 查看信息)
select_from_arr "${arr_function[*]}"
num=$?
echo "选择了 [${arr_function[(($num - 1))]}]"

case $num in
"1") # 视频压制
    arr_function=(单文件模式 文件夹模式 根据config文件处理 根据vpy文件处理 压制小档)
    select_from_arr "${arr_function[*]}"
    num=$?
    echo "选择了 [${arr_function[(($num - 1))]}]"

    case $num in
    "1")
        echo "#命令列表" >command_list

        while true; do
            ext="ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts|mov|m4a|aac|ac3|mp3|mp2|flac|ape|wav"
            list_file $ext
            file_name=$(select_file $ext)
            echo "选择了文件 [$file_name]"

            show_video_info "$file_name"
            show_audio_info "$file_name"

            file_no_ext_name=${file_name%.*} # 获取文件名 从右向左截取第一个.后的字符串
            file_ext_name=${file_name##*.}   # 获取扩展名 从左向右截取最后一个.后的字符串

            read -p "请问当前视频是否准备投往b站? [y/N]: " submit_b
            if [ "$submit_b" != "y" ]; then
                submit_b="n"
            fi

            echo -e "\n开始处理音频……"
            satisfy_b "$file_name" "audio"
            if [ "$?" == "0" -a "$submit_b" == "y" ]; then # 不满足b站要求 且 又要投b站时才转码
                echo "转码音频"
                audio=$(process_audio "$file_name" "transcode")
            else
                echo "直接抽取音频"
                audio=$(process_audio "$file_name" "extract")
            fi
            echo "音频处理完成! 音频文件名为 [$audio]"

            satisfy_b $file_name "video"
            if [ "$?" == "1" ]; then
                echo "视频已满足b站要求 直接提取"
                ffmpeg -hide_banner -loglevel quiet -i "$file_name" -c copy -bsf: h264_mp4toannexb -f h264 "$file_name.264"
                MP4Box -quiet -add "$file_name.264" -add "$file_name.m4a" -new "$file_name.mp4"
                ffmpeg -hide_banner -loglevel quiet -i "$file_name.mp4" -c copy "$file_no_ext_name.flv"
                rm "$file_name.m4a" "$file_name.264" "$file_name.mp4"
                echo -e "合并完成!\n"
            else # 视频需要重新编码
                config_transcode "$file_name" "$submit_b"
                merge_av "$file_name" "$?" "$audio"
                if [ "$submit_b" == "y" ]; then
                    echo "ffmpeg -nostdin -hide_banner -loglevel quiet -i \"$file_name.mp4\" -c copy \"$file_no_ext_name.flv\"" >>command_list
                    echo "rm \"$file_name.mp4\"" >>command_list
                fi
            fi

            read -p "继续添加任务吗? [Y/n]: " add_more
            if [ "$add_more" == "n" ]; then
                break
            else
                continue
            fi
        done

        execute_command
        ;;
    "2")
        echo "#命令列表" >command_list

        for file in $(find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts|mov)"); do
            file_name=$(echo $file | cut -d / -f 2)
            echo -e "\n当前正在处理 [$file_name]"
            show_video_info "$file_name"
            show_audio_info "$file_name"

            audio_format=$(mediainfo --Inform="Audio;%Format%" "$file_name")
            audio_bit_rate=$(mediainfo --Inform="Audio;%BitRate%" "$file_name")
            if [ "$audio_format" == "AAC" -a "$audio_bit_rate" -lt 192000 ]; then
                echo "直接抽取音频"
                audio=$(process_audio "$file_name" "extract")
            else
                echo "转码音频"
                audio=$(process_audio "$file_name" "transcode")
            fi

            # 文件夹批处理模式下 必然 投b站 无字幕 x264编码 采用默认码率
            config_transcode "$file_name" "y" "no_subtitle" "x264" "default_bit_rate"
            echo "MP4Box -quiet -add \"$file_name.264\" -add \"$audio\" -new \"$file_name.mp4\"" >>command_list
            echo "ffmpeg -nostdin -hide_banner -loglevel quiet -i \"$file_name.mp4\" -c copy \"${file_name%.*}.flv\"" >>command_list
            echo "rm \"$file_name.264\" \"$audio\" \"$file_name.mp4\"" >>command_list
        done

        execute_command
        ;;
    "3")
        echo "#命令列表" >command_list
        ;;
    "4") ;;

    esac
    ;;
"2") # 音频处理
    ext="ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts|mov|m4a|aac|ac3|mp3|mp2|flac|ape|wav"
    list_file $ext
    file_name=$(select_file $ext)
    echo -e "\n选择了文件 [ $file_name ]"
    show_audio_info $file_name

    arr_function=(从视频中直接提取 转码成192码率的AAC)
    select_from_arr "${arr_function[*]}"
    num=$?
    echo "选择了 [${arr_function[(($num - 1))]}]"
    case $num in
    "1")
        process_audio $file_name "extract"
        ;;
    "2")
        process_audio $file_name "transcode"
        ;;
    esac
    ;;
"3")
    ext="ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts|m4a|aac|ac3|mp3|mp2|flac|ape|wav"
    list_file $ext
    file_name=$(select_file $ext)
    echo "选择了文件 [$file_name]"

    arr_function=(mp4 flv ts)
    select_from_arr "${arr_function[*]}"
    format=${arr_function[(($? - 1))]}
    echo "选择了目标格式 [$format]"

    echo -e "\n开始转换格式……"
    ffmpeg -nostdin -hide_banner -loglevel panic -i "$file_name" -c copy "$file_name.$format"
    echo "格式转换完成!"
    ;;
"4") ;;

"5")
    ext="ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts|m4a|aac|ac3|mp3|mp2|flac|ape|wav"
    list_file $ext
    file_name=$(select_file $ext)
    echo "选择了文件 [ $file_name ]"

    show_video_info $file_name
    show_audio_info $file_name
    ;;
esac
IFS=$SAVEIFS
