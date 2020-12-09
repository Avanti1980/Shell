command="mkvmerge -q -o output_temp.mkv"
del="rm output_temp.mkv"
first=1
while true
do
    echo "当前目录所有mp4文件如下:"
    num=0
    SAVEIFS=$IFS
    IFS=`echo -en "\n\b"`
    file_list=`find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(mp4)"`
    for file in $file_list
    do
        ((num++))
        file_name=`echo $file | cut -d / -f 2`
        echo "$num. $file_name"
    done

    read -p "请选择要合并的mp4文件序号: " select_index
    num=0
    for file in $file_list
    do
        ((num++))
        if [ "$select_index" == "$num" ]
        then
            file_name=`echo $file | cut -d / -f 2`
            break
        fi
    done
    MP4Box -quiet -add "$file_name" -new "$file_name.mp4"
    del="$del \"$file_name.mp4\""
    
    echo $first
    if [ "$first" == "1" ]
    then
        command="$command \"$file_name.mp4\""
        output_file_name="$file_name.merge.mp4" # 合并后文件名为第一个文件名+.merge.mp4
        first=0
    else
        command="$command + \"$file_name.mp4\""
    fi

    read -p "继续添加文件 [Y/n]: " add_more
    if [ "$add_more" == "n" ]
    then
        break
    else
        continue
    fi
done

echo $command
eval $command

ffmpeg -hide_banner -loglevel quiet -i output_temp.mkv -codec copy "$output_file_name"

echo $del
eval $del
