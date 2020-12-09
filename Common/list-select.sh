# ext="ts|mp4|mkv|aac|ac3|flac"
# list_file $ext
function list_file() {
    echo -e "\n当前目录可选择文件如下:"
    file_list=$(find . -maxdepth 1 -regextype posix-extended -iregex ".*\.($1)")

    num=0
    for file in $file_list; do
        ((num++))
        if [ "$num" == "1" ]; then
            echo "$num. $(echo "$file" | cut -d / -f 2) (默认)"
        else
            echo "$num. $(echo "$file" | cut -d / -f 2)"
        fi
    done
}

# file_name=$(select_file $ext)
function select_file() {
    file_list=$(find . -maxdepth 1 -regextype posix-extended -iregex ".*\.($1)")

    read -p "请选择(序号): " select_index
    num=0
    for file in $file_list; do
        ((num++))
        if [ "$num" == "1" ]; then
            default_file=$(echo "$file" | cut -d / -f 2) # 默认选择列表第一个文件
        fi
        if [ "$select_index" == "$num" ]; then
            default_file=$(echo "$file" | cut -d / -f 2) # 找到了选择的文件
            break
        fi
    done
    echo $default_file
}

# arr_function=(320_AAC FLAC ALAC)
# select_from_arr "${arr_function[*]}"
function select_from_arr() {
    num=0
    arr=$1
    for element in ${arr[*]}; do
        ((num++))
        if [ "$num" == "1" ]; then
            echo -e "\n$num. $element (默认);"
        else
            echo "$num. $element;"
        fi
    done

    read -p "请选择(序号): " select_task

    num=0
    for element in ${arr[*]}; do
        ((num++))
        if [ "$num" == "$select_task" ]; then
            return $select_task
        fi
    done
    return 1
}
