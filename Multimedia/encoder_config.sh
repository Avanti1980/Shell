# 批量处理某一目录下所有视频

echo '#命令列表' > command_list

SAVEIFS=$IFS
IFS=`echo -en "\n\b"`

video_list=`find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts)"`

for file in $video_list
do
    file_name=`echo $file | cut -d / -f 2`
    echo -e "\n当前正在处理$file_name"

    # 获取文件名和扩展名
    video_no_ext_name=${file_name%.*}
    video_ext_name=${file_name##*.}

    del="rm \"$file_name.m4a\" \"$file_name.vpy\""

    audio_format=`mediainfo --Inform="Audio;%Format%" "$file_name"` # AAC or AC3 or MPEG Audio Layer2/3
    audio_bit_rate=`mediainfo --Inform="Audio;%BitRate%" "$file_name"`
    audio_channels=`mediainfo --Inform="Audio;%Channel(s)%" "$file_name"`
    if [ "$audio_format" == "AAC" ] && [ "$audio_bit_rate" -lt 192000 ] && [ "$audio_channels" -lt 3 ]
    then
        echo "ffmpeg -nostdin -hide_banner -loglevel quiet -i \"$file_name\" -c:a copy -bsf:a aac_adtstoasc -vn \"$file_name.m4a\"" >> command_list
    else
        echo "ffmpeg -nostdin -hide_banner -loglevel quiet -i \"$file_name\" -c:a aac -ar 48000 -b:a 192k -vn \"$file_name.m4a\"" >> command_list
    fi

    echo "import vapoursynth as vs" > "$file_name.vpy"
    echo "import sys" >> "$file_name.vpy"
    echo "import havsfunc as haf" >> "$file_name.vpy"
    echo "import mvsfunc as mvf" >> "$file_name.vpy"
    echo "core = vs.get_core()" >> "$file_name.vpy"
    # echo "core.max_cache_size = 2000" >> "$file_name.vpy"

    video_muxer_format=`mediainfo --Inform="General;%Format%" "$file_name"` # 封装格式
    video_encoder_format=`mediainfo --Inform="Video;%Format%" "$file_name"` # 编码格式
    video_width=`mediainfo --Inform="Video;%Width%" "$file_name"`
    video_height=`mediainfo --Inform="Video;%Height%" "$file_name"`
    video_dar=`mediainfo --Inform="Video;%DisplayAspectRatio%" "$file_name"`
    video_fps=`mediainfo --Inform="Video;%FrameRate%" "$file_name"`
    if [ "$video_dar" == "1.333" ]
    then
        video_dar1=4
        video_dar2=3
    elif [ "$video_dar" == "1.778" ]
    then
        video_dar1=16
        video_dar2=9
    fi

    echo "当前视频 封装方式<$video_muxer_format> 编码方式<$video_encoder_format> 分辨率<$video_width*$video_height> 帧率<$video_fps> 显示比例<$video_dar1:$video_dar2>"

    # 封装格式必须是MPEG-TS或者MPEG-PS 且 编码格式是MPEG Video
    if [ "$video_encoder_format" == "MPEG Video" ] && [ "$video_muxer_format" == "MPEG-TS" -o "$video_muxer_format" == "MPEG-PS" ]
    then
        echo "创建索引"
        d2vwitch "$file_name"
        echo "clip = core.d2v.Source(input=r'$file_name.d2v', threads=1)" >> "$file_name.vpy"
        echo "clip = mvf.Depth(clip, depth=16)" >> "$file_name.vpy"
        del="$del \"$file_name.d2v\""
    else
        echo "clip = core.lsmas.LWLibavSource(source=r'$file_name', format='yuv420p16')" >> "$file_name.vpy"
        del="$del \"$file_name.lwi\""
    fi

    if [ "$video_fps" == "50.000" ]
    then
        echo "clip = haf.ChangeFPS(clip, 25, 1)" >> "$file_name.vpy"
    fi

    video_scantype=`mediainfo --Inform="Video;%ScanType%" "$file_name"` # Interlaced or Progressive
    if [ "$video_scantype" != "Progressive" ]
    then
        video_scanorder=`mediainfo --Inform="Video;%ScanOrder%" "$file_name"` # TFF or BFF
        echo "当前视频扫描方式<$video_scantype> 扫描顺序<$video_scanorder>"
        if [ "$video_scanorder" == "TFF" ]
        then
            echo "clip = haf.QTGMC(clip, Preset='Slow', FPSDivisor=2, TFF=True)" >> "$file_name.vpy"
            #echo 注释掉反交错了
        else
            echo "clip = haf.QTGMC(clip, Preset='Slow', FPSDivisor=2, TFF=False)" >> "$file_name.vpy"
        fi
    fi

    ((sar1=$video_dar1*$video_height))
    sar="--sar $sar1:$sar2"
    

    # 需要特殊处理的
    if [ "$video_width" == "720" ] && [ "$video_height" == "576" ]
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

    if [ "$video_width" == "720" ] && [ "$video_height" == "480" ]
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

    if [ "$video_width" == "1440" ] && [ "$video_height" == "1080" ]
    then
        if [ "$video_dar" == "16:9" ]
        then
            echo "sar将设置成4:3"
            sar="--sar 4:3"
        fi
    fi

    if [ "$video_width" == "1280" ] && [ "$video_height" == "1080" ]
    then
        if [ "$video_dar" == "16:9" ]
        then
            echo "sar将设置成3:2"
            sar="--sar 3:2"
        fi
    fi

    # echo "clip = mvf.BM3D(clip, sigma=[3,3,3], radius1=1)" >> "$file_name.vpy"
    echo "clip = core.knlm.KNLMeansCL(clip, d=1, a=2, s=4, device_type='auto')" >> "$file_name.vpy"
    echo "clip.set_output()" >> "$file_name.vpy"

    if [ "$video_height" -gt 720 ]
    then
        bit_rate_2pass=3050
    elif [ "$video_height" -gt 480 ]
    then
        bit_rate_2pass=2040
    else
        bit_rate_2pass=1820
    fi
    echo "目标码率是$bit_rate_2pass"

    crf="--crf 21.0"
    keyint=250

    echo "vspipe \"$file_name.vpy\" - --y4m \| x264 --demuxer y4m $crf --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 --pass 1 --slow-firstpass --stats temp.stats -o \"$file_name.pass1.264\" -" >> command_list

    echo "vspipe \"$file_name.vpy\" - --y4m \| x264 --demuxer y4m --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 --pass 2 --bitrate $bit_rate_2pass --stats temp.stats -o \"$file_name.pass2.264\" -" >> command_list

    echo "MP4Box -add \"$file_name.pass2.264\" -add \"$file_name.m4a\" -new \"$file_name.mp4\"" >> command_list
    echo "ffmpeg -nostdin -hide_banner -loglevel quiet -i \"$file_name.mp4\" -c copy \"$video_no_ext_name.flv\"" >> command_list
    
    del="$del \"$file_name.pass1.264\" \"$file_name.pass2.264\" \"$file_name.mp4\" temp.stats*"

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
