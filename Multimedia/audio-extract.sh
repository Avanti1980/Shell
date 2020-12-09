SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
source list-select.sh

ext="ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts|mov"
list_file $ext
file_name=$(select_file $ext)
echo -e "\n选择了<$file_name>, 文件信息如下:"
ffprobe -hide_banner "$file_name"

# 记录每条音频的编码格式
audio_format=$(ffprobe -hide_banner -loglevel quiet -print_format compact -show_format -show_streams "$file_name" | grep codec_type=audio | cut -d \| -f 3 | cut -d = -f 2)

# 记录每条音频对应的index
stream_index=$(ffprobe -hide_banner -loglevel quiet -print_format compact -show_format -show_streams "$file_name" | grep codec_type=audio | cut -d \| -f 2 | cut -d = -f 2)

echo -e "\n"

num=0
for a in $audio_format; do
    ((num++))
    index=$(echo $stream_index | cut -d ' ' -f $num)
    if [ $a == aac -o $a == alac ]; then
        ffmpeg -hide_banner -loglevel quiet -i "$file_name" -map 0:$index -vn -acodec copy "$file_name.m4a"
    else
        ffmpeg -hide_banner -loglevel quiet -i "$file_name" -map 0:$index -vn -acodec copy "$file_name.$a"
    fi
    echo -e "成功提取$a音频"
done

IFS=$SAVEIFS
