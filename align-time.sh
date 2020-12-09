#!/usr/bin/env bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

ass_name=$(echo $(echo $1 | sed 's/\(.*\)\.ass/\1/g')) # 获取文件名

if [ -f "$ass_name-align-time.ass" ]; then
    rm "$ass_name-align-time.ass"
else
    touch "$ass_name-align-time.ass"
fi

jap_flag=0
num=0

while read -r line || [ -n "$line" ]; do # 一行一行处理

    if [[ "$line" =~ "Dialogue:" ]] && [[ "$line" =~ "晨间-对白日文" ]]; then # 日文行

        jap_flag=1

        jap_no_content=$(echo $line | sed 's/\(.*\),,.*/\1,,/g') # 提取除内容外的所有部分
        jap_time=$(echo $line | cut -d ',' -f 2-3)               # 提取日文行时间轴

        echo $line >>$ass_name-align-time.ass

    elif [[ "$line" =~ "Dialogue:" ]] && [[ "$line" =~ "晨间-对白中文" ]]; then # 中文行

        if [[ "$line" =~ "\\N" ]]; then # 后期做的特效行 中日文都在同一行
            echo $line >>$ass_name-align-time.ass
            continue
        fi

        if [ $jap_flag == 1 ]; then # 如果上一行是日文行

            chn_time=$(echo $line | cut -d ',' -f 2-3) # 提取中文行时间轴

            if [ "$jap_time" == "$chn_time" ]; then # 如果时间轴匹配 直接输出
                echo $line >>$ass_name-align-time.ass
            else
                ((num++))
                echo 发现第$num处不匹配：
                echo $jap_no_content
                echo $line | sed 's/\(.*\),,.*/\1,,/g'
                chn_content=$(echo $line | sed 's/.*0,,\(.*\)/\1/g') # 提取中文行内容
                chn_no_content=${jap_no_content/对白日文/对白中文}
                echo $chn_no_content$chn_content >>$ass_name-align-time.ass
            fi

            jap_flag=0
        fi
    else
        echo "$line" >>$ass_name-align-time.ass # 其他行不变
    fi

done <$1

echo 处理完毕 共发现$num处不匹配！
