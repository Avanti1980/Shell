SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
source list-select.sh
source media-utility.sh

ext="ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts|mov|m4a|aac|ac3|mp3|mp2|flac|ape|wav"
list_file $ext
file_name=$(select_file $ext)
echo -e "\n选择了<$file_name>, 文件信息如下:"
ffprobe -hide_banner -i "$file_name"
