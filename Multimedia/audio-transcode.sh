SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
source list-select.sh

ext="ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts|mov|m4a|aac|ac3|mp3|mp2|flac|ape|wav|mxf"
list_file $ext
file_name=$(select_file $ext)
echo -e "\n选择了<$file_name>, 文件信息如下:"
ffprobe -hide_banner "$file_name"

arr_function=(FLAC ALAC 320_AAC 192_AAC 128_AAC 64_AAC 32_AAC 16_AAC)
select_from_arr "${arr_function[*]}"
num=$?
echo "选择了 [${arr_function[(($num - 1))]}]"
case $num in
"1")
    ffmpeg -hide_banner -i "$file_name" -vn -c:a flac "$file_name.flac"
    ;;
"2")
    ffmpeg -hide_banner -i "$file_name" -vn -c:a alac "$file_name.m4a"
    ;;
"3")
    ffmpeg -hide_banner -i "$file_name" -vn -c:a aac -ar 48000 -b:a 320k "$file_name.m4a"
    ;;
"4")
    ffmpeg -hide_banner -i "$file_name" -vn -c:a aac -ar 48000 -b:a 192k "$file_name.m4a"
    ;;
"5")
    ffmpeg -hide_banner -i "$file_name" -vn -c:a aac -ar 48000 -b:a 128k "$file_name.m4a"
    ;;
"6")
    ffmpeg -hide_banner -i "$file_name" -vn -c:a aac -ar 48000 -b:a 64k "$file_name.m4a"
    ;;
"7")
    ffmpeg -hide_banner -i "$file_name" -vn -c:a aac -ar 48000 -b:a 32k "$file_name.m4a"
    ;;
"8")
    ffmpeg -hide_banner -i "$file_name" -vn -c:a aac -ar 48000 -b:a 16k "$file_name.m4a"
    ;;
esac

IFS=$SAVEIFS
