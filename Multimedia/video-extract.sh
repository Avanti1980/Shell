SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
source list-select.sh

ext="ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts|mov"
list_file $ext
file_name=$(select_file $ext)
echo -e "\n选择了<$file_name>, 文件信息如下:"
ffprobe -hide_banner "$file_name"

# 记录每条视频频的编码格式
video_format=$(ffprobe -hide_banner -loglevel quiet -print_format compact -show_format -show_streams "$file_name" | grep codec_type=video | cut -d \| -f 3 | cut -d = -f 2)

# 记录每条视频对应的index
stream_index=$(ffprobe -hide_banner -loglevel quiet -print_format compact -show_format -show_streams "$file_name" | grep codec_type=video | cut -d \| -f 2 | cut -d = -f 2)

echo -e "\n"

num=0
for a in $video_format; do
    echo $a
    ((num++))
    index=$(echo $stream_index | cut -d ' ' -f $num)
    if [ $a == mpeg2video ]; then
        ffmpeg -hide_banner -loglevel quiet -i "$file_name" -map 0:$index -an -vcodec copy "$file_name.ts"
    fi
    if [ $a == h264 ]; then
        ffmpeg -hide_banner -loglevel quiet -i "$file_name" -map 0:$index -an -vcodec copy "$file_name.264"
    fi
    echo -e "成功提取$a视频"
done

IFS=$SAVEIFS
