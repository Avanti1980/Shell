echo "#命令列表" > command_list

SAVEIFS=$IFS
IFS=`echo -en "\n\b"`

while true
do
    echo "当前目录所有视频文件如下:"
    num=0

    # . -maxdepth 1 表示只考虑当前目录, -iregex 表示按正则表达式搜索 同时忽略大小写的区别
    file_list=`find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts)"`
    for file in $file_list
    do
        ((num++))
        file_name=`echo "$file" | cut -d / -f 2`
        echo "$num. $file_name"
    done

    read -p "请选择要处理的文件序号: " select_index

    num=0
    for file in $file_list
    do
        ((num++))
        if [ "$select_index" == "$num" ]
        then
            file_name=`echo "$file" | cut -d / -f 2`
            echo -e "\n您选择处理的文件是<$file_name>\n"
            break
        fi
    done

    # 获取文件名和扩展名
    file_no_ext_name=${file_name%.*}
    file_ext_name=${file_name##*.}

    # 判断是否有同名的txt配置文件
    if [ -f "$file_name.txt" ]
    then
        echo "找到txt配置文件"
        
    fi

    # 创建删除命令
    del="rm"

    read -p "请问当前视频是否准备投往b站? [y/N]: " submit_b
    if [ "$submit_b" != "y" ]
    then
        submit_b="n"
    fi

    # 读取音频格式 采样率 码率 通道数
    audio_format=`mediainfo --Inform="Audio;%Format%" "$file_name"` # AAC or AC3 or MPEG Audio Layer2/3
    audio_sampling_rate=`mediainfo --Inform="Audio;%SamplingRate%" "$file_name"` # 44100 or 48000
    audio_bit_rate=`mediainfo --Inform="Audio;%BitRate%" "$file_name"`
    audio_channels=`mediainfo --Inform="Audio;%Channel(s)%" "$file_name"`
    echo "当前音频格式<$audio_format> 采样率<$audio_sampling_rate> 码率<$audio_bit_rate> 通道数<$audio_channels>"

    re_encoder=1
    if [ "$audio_format" == "AAC" ] && [ "$audio_bit_rate" -lt 192000 ] && [ "$audio_channels" -lt 3 ] && [ "$submit_b" == "y" ]
    then
        echo "当前音频已满足b站要求 直接提取"
        re_encoder=0
    else
        read -p "当前音频不满足b站要求 1. 按b站要求(默认); 2. 直接提取; 请选择: " select_index
        if [ "$select_index" == "2" ]
        then 
            re_encoder=0
        else
            re_encoder=1
        fi
    fi

    if [ "$re_encoder" == "0" ] # 直接提取
    then
        case "$audio_format" in
        "AAC")
            ffmpeg -hide_banner -loglevel quiet -i "$file_name" -c:a copy -bsf:a aac_adtstoasc -vn "$file_name.m4a"
            del="$del \"$file_name.m4a\""
            ;;
	    "AC-3")
            ffmpeg -hide_banner -loglevel quiet -i "$file_name" -vn -acodec copy "$file_name.ac3"
            del="$del \"$file_name.ac3\""
            ;;
        "AC-3AC-3") #这是ffmpeg的bug 6声道的AC3的音频都会重复显示两遍
            ffmpeg -hide_banner -loglevel quiet -i "$file_name" -vn -acodec copy "$file_name.ac3"
	        audio_format="AC-3"
            del="$del \"$file_name.ac3\""
            ;;
        "MPEG Audio")
            echo "待添加处理代码"
            del="$del \"$file_name.mp3\""
            ;;
        esac
    else # 重新编码音频
        audio_format="AAC"
        ffmpeg -hide_banner -loglevel quiet -i "$file_name" -c:a aac -ar 48000 -b:a 192k -vn "$file_name.m4a"
        del="$del \"$file_name.m4a\""
    fi

    echo -e "音频处理完成\n"

    video_muxer_format=`mediainfo --Inform="General;%Format%" "$file_name"` # 封装格式
    video_encoder_format=`mediainfo --Inform="Video;%Format%" "$file_name"` # 编码格式
    video_bit_rate=`mediainfo --Inform="Video;%BitRate%" "$file_name"`
    video_fps=`mediainfo --Inform="Video;%FrameRate%" "$file_name"`
    echo -e "当前视频 封装方式<$video_muxer_format>  编码格式<$video_encoder_format> 码率<$video_bit_rate> 帧率<$video_fps>\n"

    re_encoder=1
    if [ "$video_encoder_format" == "AVC" ] && [ "$video_bit_rate" -lt 1800000 ] && [ "$submit_b" == "y" ]
    then
        read -p "当前视频已满足b站要求 不重新编码直接输出? [y/N]: " select_index
        if [ "$select_index" == "y" ]
        then
            re_encoder=0
        fi
    fi

    if [ "$re_encoder" == "0" ]
    then
        ffmpeg -hide_banner -loglevel quiet -i "$file_name" -c copy -bsf: h264_mp4toannexb -f h264 "$file_name.264"
        MP4Box -quiet -add "$file_name.264" -add "$file_name.m4a" -new "$file_name.mp4"
        ffmpeg -hide_banner -loglevel quiet -i "$file_name.mp4" -c copy "$file_no_ext_name.flv"
        del="$del \"$file_name.264\" \"$file_name.mp4\""
        echo -e "合并完成!\n"
        eval $del
    else
        del="$del \"$file_name.vpy\""
        echo "开始设置vpy脚本"
        echo "import vapoursynth as vs" > "$file_name.vpy"
        echo "import sys" >> "$file_name.vpy"
        echo "import havsfunc as haf" >> "$file_name.vpy"
        echo "import mvsfunc as mvf" >> "$file_name.vpy"
        echo "core = vs.get_core()" >> "$file_name.vpy"
        # echo "core.max_cache_size = 2000" >> "$file_name.vpy"

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
        video_width=`mediainfo --Inform="Video;%Width%" "$file_name"`
        video_height=`mediainfo --Inform="Video;%Height%" "$file_name"`
        video_dar=`mediainfo --Inform="Video;%DisplayAspectRatio%" "$file_name"`
        if [ "$video_dar" == "1.333" ]
        then
            video_dar1=4
            video_dar2=3
        elif [ "$video_dar" == "1.778" ]
        then
            video_dar1=16
            video_dar2=9
        fi
        
        if [ -n "$video_scantype" ] && [ "$video_scantype" != "Progressive" ]
        then
            video_scanorder=`mediainfo --Inform="Video;%ScanOrder%" "$file_name"` # TFF or BFF
            echo -e "\n当前视频扫描方式<$video_scantype> 扫描顺序<$video_scanorder> 分辨率<$video_width*$video_height> 显示比例<$video_dar1:$video_dar2>\n"

            read -p "1. Yadif; 2. QTGMC(默认); 请选择反交错滤镜: " interlace_filter
            read -p "1. 倍帧; 2. 保持帧率(默认); 请选择: " double_rate
            if [ "$double_rate" != "1" ]
            then
                double_rate="2"
            fi

            if [ "$interlace_filter" == "1" ] # yadif
            then
                if [ "$double_rate" == "2" ]
                then
                    double_rate=0
                fi

                if [ "$video_scanorder" == "TFF" ]
                then
                    echo "clip = core.yadifmod.Yadifmod(clip, core.nnedi3.nnedi3(clip, field=1, opt=2), order=1, field=-1, mode=$double_rate)" >> "$file_name.vpy"
                else
                    echo "clip = core.yadifmod.Yadifmod(clip, core.nnedi3.nnedi3(clip, field=0, opt=2), order=0, field=-1, mode=$double_rate)" >> "$file_name.vpy"
                fi
            else # qtgmc
                if [ "$video_scanorder" == "TFF" ]
                then
                    echo "clip = haf.QTGMC(clip, Preset='Slow', FPSDivisor=$double_rate, TFF=True)" >> "$file_name.vpy"
                else
                    echo "clip = haf.QTGMC(clip, Preset='Slow', FPSDivisor=$double_rate, TFF=False)" >> "$file_name.vpy"
                fi
            fi
        else
            echo -e "\n当前视频扫描方式<$video_scantype> 分辨率<$video_width*$video_height> 显示比例<$video_dar>\n"
        fi

        ((sar1=$video_dar1*$video_height))
        ((sar2=$video_dar2*$video_width))
        sar="--sar $sar1:$sar2"
        echo "sar将设置成$sar1:$sar2"

        arr_width=(1920 1280 1024 960 768 720 640)
        arr_height=(1080 720 576 540 576 540 480)
        num=0
        size_list=""
        for vf in ${arr_width[@]}
        do
            ((num1=num+1))
            size_list="$format_list $num1. ${arr_width[$num]}*${arr_height[$num]};"
            ((num++))
        done

        read -p "是否拉伸视频 [y/N]: " select_index
        if [ "$select_index" == "y" ]
        then
            read -p "拉伸至 $size_list 请选择: " select_index
            ((select_index--))
            echo "clip = core.resize.Bicubic(clip, ${arr_width[$select_index]}, ${arr_height[$select_index]}, filter_param_a=0.333, filter_param_b=0.333)" >> "$file_name.vpy"
            video_height=${arr_height[$select_index]}
        fi

        # 增加黑边 是为了将小分辨率视频与大分辨率视频连接
        read -p "是否增加黑边 [y/N]: " select_index
        if [ "$select_index" == "y" ]
        then
            # 如果增加黑边 原本sar不是1:1的视频就必须先resize!!!!!
            read -p "拉伸至 $size_list 请选择: " select_index
            ((select_index--))
            ((diff_width=(${arr_width[$select_index]}-$video_width)/2))
            ((diff_height=(${arr_height[$select_index]}-$video_height)/2))
            echo "clip = core.std.AddBorders(clip, left=$diff_width, right=$diff_width, top=$diff_height, bottom=$diff_height)" >> "$file_name.vpy"
            video_height=${arr_height[$select_index]}
        fi

        echo "clip = core.knlm.KNLMeansCL(clip, d=1, a=2, s=4, device_type='auto')" >> "$file_name.vpy"

        read -p "是否添加字幕 [y/N]: " add_subtitle
        if [ "$add_subtitle" == "y" ]
        then
            echo "当前目录所有字幕文件如下:"
            num=0
            subtitle_list=`find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(ass|srt)"`
            for subtitle in $subtitle_list
            do
                ((num++))
                subtitle_name=`echo "$subtitle" | cut -d / -f 2`
                echo "$num. $subtitle_name"
            done

            read -p "请选择要添加的字幕文件序号: " select_index
            num=0
            for subtitle in $subtitle_list
            do
                ((num++))
                if [ "$select_index" == "$num" ]
                then
                    subtitle_name=`echo "$subtitle" | cut -d / -f 2`
                    echo -e "您选择字幕是<$subtitle_name>\n"
                    echo "clip = core.sub.TextFile(clip, file=r'$subtitle_name')" >> "$file_name.vpy"
                    break
                fi
            done
            echo "您未能成功选择字幕!"
        fi
        echo "clip.set_output()" >> "$file_name.vpy"

        echo -e "\n压制vpy脚本如下:"
        cat "$file_name.vpy"
        echo ""

        read -p "编码器 1. x264(默认); 2. x265; 请选择: " select_encoder
        if [ "$select_encoder" != "2" ]
        then
            select_encoder="1"
        fi

        if [ "$video_height" -gt 720 ]
        then
            bit_rate_2pass=3080
        elif [ "$video_height" -gt 480 ]
        then
            bit_rate_2pass=2040
        else
            bit_rate_2pass=1820
        fi

        read -p "手动设置码率 [y/N]: " bit_rate_setting
        if [ "$bit_rate_setting" == "y" ]
        then
            read -p "请输入码率: " bit_rate_2pass
        fi

        keyint=250
        if [ "$double_rate" == "1" ]
        then
            keyint=500
        fi 

        crf="--crf 21.0"
        if [ "$submit_b" == "y" ]
        then
            echo "vspipe \"$file_name.vpy\" - --y4m \| x264 --demuxer y4m $crf --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 --pass 1 --slow-firstpass --stats temp.stats -o \"$file_name.pass1.264\" -" >> command_list

            echo "vspipe \"$file_name.vpy\" - --y4m \| x264 --demuxer y4m --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 --pass 2 --bitrate $bit_rate_2pass --stats temp.stats -o \"$file_name.264\" -" >> command_list

            del="$del \"$file_name.pass1.264\" \"$file_name.264\" temp.stats*"
        else
            read -p "请输入crf参数(默认21.0): " input_crf
            if [ -n "$input_crf" ]
            then
                crf="--crf $input_crf"
            fi
            if [ "$select_encoder" == "1" ]
            then
                echo "vspipe \"$file_name.vpy\" - --y4m \| x264 --demuxer y4m $crf --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 -o \"$file_name.264\" -" >> command_list
                del="$del \"$file_name.264\""
            else
                echo "vspipe \"$file_name.vpy\" - --y4m \| ~/Encoders/x265/build/linux/x265 --y4m --preset slow $crf --ctu 32 --min-cu-size 8 --max-tu-size 32 --tu-intra-depth 2 --tu-inter-depth 2 --me 3 --subme 4 --merange 44 --no-rect --no-amp --max-merge 3 --temporal-mvp --no-early-skip --rskip --rdpenalty 0 --no-tskip --no-tskip-fast --no-strong-intra-smoothing --no-lossless --no-cu-lossless --no-constrained-intra --no-fast-intra --no-open-gop --no-temporal-layers --keyint 360 --min-keyint 1 --scenecut 40 --rc-lookahead 72 --lookahead-slices 4 --bframes 6 --bframe-bias 0 --b-adapt 2 --ref 4 --limit-refs 2 --limit-modes --weightp --weightb --aq-mode 1 --qg-size 16 --aq-strength 1.0 --cbqpoffs -3 --crqpoffs -3 --rd 4 --psy-rd 2.0 --psy-rdoq 3.0 --rdoq-level 2 --deblock -2:-2 --no-sao --no-sao-non-deblock --pbratio 1.2 --qcomp 0.6 --input-depth 16 $sar -o \"$file_name.hevc\" -" >> command_list
                del="$del \"$file_name.hevc\""
            fi
        fi
	
        if [ "$select_encoder" == "1" ]
        then
            case "$audio_format" in
            "AAC")
                echo "MP4Box -quiet -add \"$file_name.264\" -add \"$file_name.m4a\" -new \"$file_name.mp4\"" >> command_list
                ;;
            "AC-3")
                echo "MP4Box -quiet -add \"$file_name.264\" -add \"$file_name.ac3\" -new \"$file_name.mp4\"" >> command_list
                ;;
            "MPEG Audio")
                echo "待添加处理代码"
                ;;
            esac
        else
            case "$audio_format" in
            "AAC")
                echo "MP4Box -quiet -add \"$file_name.hevc\" -add \"$file_name.m4a\" -new \"$file_name.mp4\"" >> command_list
                ;;
            "AC-3")
                echo "MP4Box -quiet -add \"$file_name.hevc\" -add \"$file_name.ac3\" -new \"$file_name.mp4\"" >> command_list
                ;;
            "MPEG Audio")
                echo "待添加处理代码"
                ;;
            esac
        fi

        if [ "$audio_format" == "AAC" ]
        then
            echo "ffmpeg -nostdin -hide_banner -loglevel quiet -i \"$file_name.mp4\" -c copy \"$file_no_ext_name.flv\"" >> command_list
            del="$del \"$file_name.mp4\""
        fi

        echo $del >> command_list
    fi

    echo ""
    read -p "继续添加任务吗? [y/N]: " add_more
    if [ "$add_more" == "y" ]
    then
        continue
    else
        break
    fi
done

echo -e "\n所有命令如下:"
cat command_list

echo -e "\n开始压制 请稍等"
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
