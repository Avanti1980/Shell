num="$1"
while [ $num -le "$2" ]; do
    if [ $4 -eq 0 ]; then
        if [ $num -lt 10 ]; then
            wget -t 0 -q --show-progress -P . $30$num.pdf # 服务器上文件命名各位数已经补零了
        else
            wget -t 0 -q --show-progress -P . $3$num.pdf
        fi
    else
        if [ $num -lt 10 ]; then
            file_name=$(echo $3 | sed -n "s/.*\/\(.*\)/\1/p")
            wget -t 0 -q --show-progress -O "${file_name}0$num.pdf" $3$num.pdf # 服务器上文件命名个位数没有补零 下载回来后将本地文件补零
        else
            wget -t 0 -q --show-progress -P . $3$num.pdf
        fi
    fi
    ((num++))
done
