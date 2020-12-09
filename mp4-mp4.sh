num=0
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
file_list=$(find ./ -regextype posix-extended -regex ".*\.(mp4|MP4|xufanxi)")
for file in $file_list; do
    ((num++))
    file_name=$(echo $file | cut -d / -f 2)
    cmd="MP4Box -add $file_name#video -add $file_name#audio -new $(echo $file_name | sed 's/\(.*\)\.xufanxi/\1/g')"
    echo $cmd
    eval $cmd
done
