#!/usr/bin/env bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

ass_name=$(echo $(echo $1 | sed 's/\(.*\)\.ass/\1/g')) # 获取文件名

if [ -f "$ass_name-chn-jap.ass" ]; then
    rm "$ass_name-chn-jap.ass"
else
    touch "$ass_name-chn-jap.ass"
fi

# 初始化时间轴和内容
time="绯红"
no_content=""
content=""

num=0
merge_flag=1

while read -r line || [[ -n "$line" ]]; do # 一行一行处理

    line=${line//\\N/ }
    line=${line//｡/ }
    line=${line//。/ }
    line=${line//♬/}
    line=${line//➡/ }
    line=${line//…/ }
    line=${line//！/ }
    line=${line//？/ }
    line=${line//!/ }
    line=${line//\?/ }
    line=${line//≪/ }
    line=${line//・/ }
    line=${line//→/ }
    line=${line//　/ }
    line=${line//    / }
    line=${line//   / }
    line=${line//  / }
    line=${line//,, /,,}
    line=${line//0000/0}

    if [[ "$line" =~ "Dialogue:" ]]; then # 如果含有Dialogue:
        if [[ "$line" =~ "Default" ]]; then # 如果含有Default 相当于忽略所有Rubi样式的行

            line=$(echo "$line" | sed 's/{\\pos\([0-9,()]*\)}//g')             # 去掉类似{\pos(184,678)}这种
            line=$(echo "$line" | sed 's/{\\c&H\([0-9a-zA-Z]*\)&}//g')         # 去掉类似{\c&H00ffff&}这种
            line=$(echo "$line" | sed 's/{\\pos\(.*\)&}//g')                   # 去掉类似{\pos(584,678)\c&H00ffff&}这种

            line_no_content=$(echo $line | sed 's/\(.*\),.*/\1,/g')            # 提取除内容外的所有部分
            line_content=$(echo $line | sed 's/.*0,,\(.*\)/\1/g' | tr -d '\r') # 提取内容 并删掉最后的换行符
            line_time=$(echo $line | cut -d ',' -f 2-3)                        # 提取时间轴

            if [ "$line_time" != "$time" ]; then # 遇到新行

                if [ -n "$content" ]; then # 将之前累积的内容输出
                    line_jap=${no_content/Default/晨间-对白日文}
                    echo $line_jap$content >>$ass_name-chn-jap.ass
                    line_chn=${no_content/Default/晨间-对白中文}
                    echo $line_chn >>$ass_name-chn-jap.ass

                    if [ "$merge_flag" == 1 ]; then
                        echo 合并后的行为：
                        echo -e $line_jap$content"\n"
                    fi
                fi

                # 重置时间轴和内容
                time=$line_time
                no_content=$line_no_content
                content=$line_content
                merge_flag=0
            else
                if [ "$merge_flag" == 0 ]; then
                    merge_flag=1
                    ((num++))
                    echo 发现第$num处合并：
                    echo $line_no_content$content
                fi
                content=$content$line_content # 非新行 直接追加内容
                echo $line_no_content$line_content
            fi
        fi
    else
        echo "$line" >>$ass_name-chn-jap.ass
    fi

done <$1

if [ -n "$content" ]; then # 输出最后一行
    line_jap=${no_content/Default/晨间-对白日文}
    echo $line_jap$content >>$ass_name-chn-jap.ass
    line_chn=${no_content/Default/晨间-对白中文}
    echo $line_chn >>$ass_name-chn-jap.ass
fi

echo 双语字幕生成完毕 共处理$num处合并！
