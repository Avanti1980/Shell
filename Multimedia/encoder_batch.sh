# 批量处理某一类视频

echo '#命令列表' > command_list

SAVEIFS=$IFS
IFS=`echo -en "\n\b"`

arr_format=(ts mp4 mkv m2ts mpg mpeg rmvb rm vob avi wmv mov mts)
num=0
format_list=""
for vf in ${arr_format[@]}
do
    ((num++))
    format_list="$format_list $num. $vf;"
done

read -p "可以批量处理的视频格式 $format_list 请选择: " select_index

((select_index--))

# . -maxdepth 1 表示只考虑当前目录, -iregex 表示按正则表达式搜索 同时忽略大小写的区别
file_list=`find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(${arr_format[$select_index]})"`

for file in $file_list
do
    file_name=`echo $file | cut -d / -f 2`
    echo -e "\n当前正在处理$file_name"

    # 获取扩展名
    dot_num=`echo "$file_name" | grep -o "\." | wc -l`
    ((dot_num++))
    file_ext_name=`echo "$file_name" | cut -d . -f $dot_num`

    del="rm"

    ffmpeg -nostdin -hide_banner -loglevel quiet -i "$file_name" -c:a aac -ar 48000 -b:a 192k -vn "$file_name.m4a"
    del="$del \"$file_name.m4a\""

    del="$del \"$file_name.vpy\""
    echo "import vapoursynth as vs" > "$file_name.vpy"
    echo "import sys" >> "$file_name.vpy"
    echo "import havsfunc as haf" >> "$file_name.vpy"
    echo "import mvsfunc as mvf" >> "$file_name.vpy"
    echo "core = vs.get_core()" >> "$file_name.vpy"
    # echo "core.max_cache_size = 2000" >> "$file_name.vpy"

    file_format=`mediainfo --Inform="Video;%Format%" "$file_name"` # MPEG Video or AVC
    file_width=`mediainfo --Inform="Video;%Width%" "$file_name"`
    file_height=`mediainfo --Inform="Video;%Height%" "$file_name"`
    file_dar=`mediainfo --Inform="Video;%DisplayAspectRatio%" "$file_name"`
    if [ "$file_dar" == "1.333" ]
    then
        video_dar="4:3"
    elif [ "$file_dar" == "1.778" ]
    then
        video_dar="16:9"
    fi

    echo "当前视频编码方式<$file_format> 分辨率<$file_width*$file_height> 显示比例$video_dar"

    if [ "$file_format" == "MPEG Video" ] && [ "$file_ext_name" != "mkv" ] && [ "$file_ext_name" != "MKV" ]
    then
        echo 创建索引
        d2vwitch "$file_name"
        echo "clip = core.d2v.Source(input=r'$file_name.d2v', threads=1)" >> "$file_name.vpy"
        echo "clip = mvf.Depth(clip, depth=16)" >> "$file_name.vpy"
        del="$del \"$file_name.d2v\""
    else
        echo "clip = core.lsmas.LWLibavSource(source=r'$file_name', format='yuv420p16')" >> "$file_name.vpy"
        del="$del \"$file_name.lwi\""
    fi

    file_scantype=`mediainfo --Inform="Video;%ScanType%" "$file_name"` # Interlaced or Progressive
    if [ "$file_scantype" != "Progressive" ]
    then
        file_scanorder=`mediainfo --Inform="Video;%ScanOrder%" "$file_name"` # TFF or BFF
        echo "当前视频扫描方式<$file_scantype> 扫描顺序<$file_scanorder>"
        if [ "$file_scanorder" == "TFF" ]
        then
            echo "clip = haf.QTGMC(clip, Preset='Slow', FPSDivisor=2, TFF=True)" >> "$file_name.vpy"
            #echo 注释掉反交错了
        else
            echo "clip = haf.QTGMC(clip, Preset='Slow', FPSDivisor=2, TFF=False)" >> "$file_name.vpy"
        fi
    fi

    sar="--sar 1:1"
    crf="--crf 21.0"

    # 需要特殊处理的
    if [ "$file_width" == "720" ] && [ "$file_height" == "576" ]
    then
        if [ "$video_dar" == "4:3" ]
        then
            echo "sar将设置成16:15"
            sar="--sar 16:15"
        else
            echo "sar将设置成64:45"
            sar="--sar 64:45"
        fi
    fi

    if [ "$file_width" == "720" ] && [ "$file_height" == "480" ]
    then
        if [ "$video_dar" == "4:3" ]
        then
            echo "sar将设置成8:9"
            sar="--sar 8:9"
        else
            echo "sar将设置成32:27"
            sar="--sar 32:27"
        fi
    fi

    # echo "clip = mvf.BM3D(clip, sigma=[3,3,3], radius1=1)" >> "$file_name.vpy"
    echo "clip = core.knlm.KNLMeansCL(clip, d=1, a=2, s=4, device_type='auto')" >> "$file_name.vpy"
    echo "clip.set_output()" >> "$file_name.vpy"

    if [ "$file_height" > 720 ]
    then
        bit_rate_2pass=3080
    elif [ "$file_height" > 480 ]
    then
        bit_rate_2pass=2050
    else
        bit_rate_2pass=1840
    fi

    keyint=250

    echo "vspipe \"$file_name.vpy\" - --y4m \| x264 --demuxer y4m $crf --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 --pass 1 --slow-firstpass --stats temp.stats -o \"$file_name.pass1.264\" -" >> command_list

    echo "vspipe \"$file_name.vpy\" - --y4m \| x264 --demuxer y4m --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 --pass 2 --bitrate $bit_rate_2pass --stats temp.stats -o \"$file_name.pass2.264\" -" >> command_list

    echo "MP4Box -add \"$file_name.pass2.264\" -add \"$file_name.m4a\" -new \"$file_name.mp4\"" >> command_list
    echo "ffmpeg -nostdin -hide_banner -loglevel quiet -i \"$file_name.mp4\" -c copy \"$file_name.flv\"" >> command_list
    
    del="$del \"$file_name.pass1.264\" \"$file_name.pass2.264\" \"$file_name.mp4\" temp.stats"

    echo $del >> command_list
done

echo "所有命令如下:"
cat command_list

echo "开始压制 请稍等"
while read command_line
do
    if [ -z "$command_line" ] || [ ${command_line:0:1} == "#" ]
    then
        continue
    fi
    echo $command_line
    eval $command_line
done < command_list

rm command_list

IFS=$SAVEIFS
