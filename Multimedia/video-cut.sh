# 该脚本有两个输入参数 分别是起始帧数和结束帧数

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
source list-select.sh

ext="ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts|mov|dat"
list_file $ext
file_name=$(select_file $ext)
echo -e "\n选择了<$file_name>, 文件信息如下:"
ffprobe -hide_banner "$file_name"

# read -p "请输入起始帧数: " start_frame
# read -p "请输入结束帧数: " end_frame

echo -e "\n"

# 获取视频帧率
video_info=$(ffprobe -hide_banner -loglevel quiet -print_format compact -show_format -show_streams "$file_name" | grep codec_type=video)

avg_frame_rate=${video_info#*"avg_frame_rate="}

numerator=$(echo $avg_frame_rate | cut -d \| -f 1 | cut -d / -f 1)
denominator=$(echo $avg_frame_rate | cut -d \| -f 1 | cut -d / -f 2)

hour_frame=$((3600 * $numerator / $denominator))
minute_frame=$((60 * $numerator / $denominator))
second_frame=$(($numerator / $denominator))

# 将帧数转化为对应的时间

hour=$(($1 / $hour_frame))
temp=$(($1 % $hour_frame))
minute=$(($temp / $minute_frame))
temp=$(($1 % $minute_frame))
second=$(($temp / $second_frame))
temp=$(($1 % $second_frame))
msec=$(($temp * 40))
start_time="$hour:$minute:$second.$msec"

hour=$(($2 / $hour_frame))
temp=$(($2 % $hour_frame))
minute=$(($temp / $minute_frame))
temp=$(($2 % $minute_frame))
second=$(($temp / $second_frame))
temp=$(($2 % $second_frame))
msec=$(($temp * 40))
end_time="$hour:$minute:$second.$msec"

echo $start_time
echo $end_time

file_no_ext_name=${file_name%.*} # 获取文件名 从右向左截取第一个.后的字符串
file_ext_name=${file_name##*.}   # 获取扩展名 从左向右截取最后一个.后的字符串

if [ $file_ext_name == DAT ]; then
    file_ext_name=ts
fi

echo "ffmpeg -hide_banner -loglevel quiet -i \"$file_name\" -c copy -ss $start_time -to $end_time \"$file_no_ext_name-cut.$file_ext_name\""

ffmpeg -hide_banner -loglevel quiet -i "$file_name" -c copy -ss $start_time -to $end_time "$file_no_ext_name-cut.$file_ext_name"

# ffmpeg -hide_banner -loglevel quiet -i "$file_name" -vn -c:a aac -ar 48000 -b:a 64k -ss $start_time -to $end_time "$file_no_ext_name-cut-64.m4a"

# ffmpeg -hide_banner -loglevel quiet -i "$file_name" -vn -c copy -ss $start_time -to $end_time "$file_no_ext_name-cut.mp2"

IFS=$SAVEIFS
