# 这个脚本可以通过vs合并多个视频 不过这只是个备选方案 因为不同帧率的视频想用此法合并得强行改变其中的某个帧率
audio_merge_command="mkvmerge -q -o merge.mka"
del_command="rm"

SAVEIFS=$IFS
IFS=`echo -en "\n\b"`

file_num=0

while true
do
    echo "当前目录所有视频文件如下:"
    num=0

    # . -maxdepth 1 表示只考虑当前目录, -iregex 表示按正则表达式搜索 同时忽略大小写的区别
    file_list=`find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv)"`
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
            ((file_num++))
            break
        fi
    done
    
    # 读取音频格式 采样率 码率 通道数
    audio_format=`mediainfo --Inform="Audio;%Format%" "$file_name"` # AAC or AC3 or MPEG Audio Layer2/3
    audio_sampling_rate=`mediainfo --Inform="Audio;%SamplingRate%" "$file_name"` # 44100 or 48000
    audio_bit_rate=`mediainfo --Inform="Audio;%BitRate%" "$file_name"`
    audio_channels=`mediainfo --Inform="Audio;%Channel(s)%" "$file_name"`
    echo "当前音频格式<$audio_format> 采样率<$audio_sampling_rate> 码率<$audio_bit_rate> 通道数<$audio_channels>"

    # 处理音频 如果某个音频已满足b站要求 可以不重新编码 但是视频不行 必须重新编码的
    if [ "$audio_format" == "AAC" ] && [ "$audio_sampling_rate" == "44100" ] && [ "$audio_bit_rate" -lt 192000 ] && [ "$audio_channels" -lt 3 ]
    then
        # 已满足b站要求 直接提取
        ffmpeg -hide_banner -loglevel quiet -i "$file_name" -c:a copy -bsf:a aac_adtstoasc -vn "$file_name.m4a"
    else
        if [ "$audio_channels" == "66" ] # 5.1声道要转成双声道
        then
            ffmpeg -hide_banner -loglevel quiet -i "$file_name" -c:a aac -ar 44100 -b:a 180k -af "pan=stereo|FL < 1.0*FL + 0.707*FC + 0.707*BL|FR < 1.0*FR + 0.707*FC + 0.707*BR" -vn "$file_name.m4a"
        else
            ffmpeg -hide_banner -loglevel quiet -i "$file_name" -c:a aac -ar 44100 -b:a 180k -vn "$file_name.m4a"
        fi
    fi
    del_command="$del_command \"$file_name.m4a\""

    # 处理视频 视频必然要重新编码的
    if [ "$file_num" == "1" ]
    then
        audio_merge_command="$audio_merge_command \"$file_name.m4a\""

        del_command="$del_command merge.vpy"

        echo "import vapoursynth as vs" > merge.vpy
        echo "import sys" >> merge.vpy
        echo "import havsfunc as haf" >> merge.vpy
        echo "import mvsfunc as mvf" >> merge.vpy
        echo "core = vs.get_core()" >> merge.vpy
        # echo "core.max_cache_size = 2000" >> merge.vpy
    else
        audio_merge_command="$audio_merge_command + \"$file_name.m4a\"" 
    fi

    video_format=`mediainfo --Inform="Video;%Format%" "$file_name"` # MPEG Video or AVC
    video_bit_rate=`mediainfo --Inform="Video;%BitRate%" "$file_name"`
    video_fps=`mediainfo --Inform="Video;%FrameRate%" "$file_name"` # 帧率
    video_width=`mediainfo --Inform="Video;%Width%" "$file_name"`
    video_height=`mediainfo --Inform="Video;%Height%" "$file_name"`
    lev=""
    if [ "$video_height" == "1080" ] || [ "$video_width" == "1920" ]
    then
        lev=" --level 4.1"
    fi
    video_dar=`mediainfo --Inform="Video;%DisplayAspectRatio%" "$file_name"`
    if [ "$video_dar" == "1.333" ]
    then
        video_dar2="4:3"
    elif [ "$video_dar" == "1.778" ]
    then
        video_dar2="16:9"
    fi
    echo "当前视频格式<$video_format> 码率<$video_bit_rate> 帧率<$video_fps> 分辨率<$video_width*$video_height> 显示比例<$video_dar2>"

     # 关系到后面删索引文件
    if [ "$video_format" == "MPEG Video" ] && [ "$file_ext_name" != "mkv" ] && [ "$file_ext_name" != "MKV" ]
    then
        echo "创建索引"
        d2vwitch "$file_name"
        echo "clip$file_num = core.d2v.Source(input=r'$file_name.d2v', threads=1)" >> merge.vpy
        echo "clip$file_num = mvf.Depth(clip$file_num, depth=16)" >> merge.vpy
        
        del_command="$del_command \"$file_name.d2v\""
    else
        echo "clip$file_num = core.lsmas.LWLibavSource(source=r'$file_name', format='yuv420p16')" >> merge.vpy

        del_command="$del_command \"$file_name.lwi\""
    fi

    # 如果帧率不是25 改成25
    if [ "$video_fps" != "25" ] && [ "$video_fps" != "25.0" ] && [ "$video_fps" != "25.00" ] && [ "$video_fps" != "25.000" ]
    then
        read -p "当前视频帧率不是25 是否修改帧率 [y/N]: " select_index
        if [ "$select_index" == "y" ]
        then
            echo "clip$file_num = haf.ChangeFPS(clip$file_num, 25, 1)" >> merge.vpy
        fi
    fi

    video_scantype=`mediainfo --Inform="Video;%ScanType%" "$file_name"` # Interlaced or Progressive

    # 获取扩展名
    dot_num=`echo "$file_name" | grep -o "\." | wc -l`
    ((dot_num++))
    file_ext_name=`echo "$file_name" | cut -d . -f $dot_num`

    if [ "$video_scantype" != "Progressive" ] # 如果不是逐行扫描 需要考虑反交错 以及顶场先还是底场先
    then
        video_scanorder=`mediainfo --Inform="Video;%ScanOrder%" "$file_name"` # TFF or BFF
        echo "当前视频扫描方式<$video_scantype> 扫描顺序<$video_scanorder>"

        read -p "1. Yadif(默认); 2. QTGMC(后续不要resize视频); 请选择反交错滤镜: " select_index
        if [ "$select_index" == "2" ]
        then
            if [ "$video_scanorder" == "TFF" ]
            then
                echo "clip$file_num = haf.QTGMC(clip$file_num, Preset='Slow', FPSDivisor=2, TFF=True)" >> merge.vpy
            else
                echo "clip$file_num = haf.QTGMC(clip$file_num, Preset='Slow', FPSDivisor=2, TFF=False)" >> merge.vpy
            fi
        else
            if [ "$video_scanorder" == "TFF" ]
            then
                echo "clip$file_num = core.yadifmod.Yadifmod(clip$file_num, core.nnedi3.nnedi3(clip, field=1, opt=2), order=1, field=-1, mode=0)" >> merge.vpy
            else
                echo "clip$file_num = core.yadifmod.Yadifmod(clip$file_num, core.nnedi3.nnedi3(clip, field=0, opt=2), order=0, field=-1, mode=0)" >> merge.vpy
            fi
        fi
    fi

    actual_height=$video_height # 影响后面选择AVC的规格
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
        if [ "$select_index" == "1" ]
        then
            lev=" --level 4.1"
        else
            lev=""
        fi
        ((select_index--))
        echo "clip$file_num = core.resize.Bicubic(clip$file_num, ${arr_width[$select_index]}, ${arr_height[$select_index]}, filter_param_a=0.333, filter_param_b=0.333)" >> merge.vpy
        actual_height=${arr_height[$select_index]}
    fi

    # 增加黑边 是为了将小分辨率视频与大分辨率视频连接
    read -p "是否增加黑边 [y/N]: " select_index
    if [ "$select_index" == "y" ]
    then
        # 如果增加黑边 原本sar不是1:1的视频就必须先resize!!!!!
        read -p "增加至 $size_list 请选择: " select_index
        if [ "$select_index" == "1" ]
        then
            lev=" --level 4.1"
        fi
        ((select_index--))
        ((diff_width=(${arr_width[$select_index]}-$video_width)/2))
        ((diff_height=(${arr_height[$select_index]}-$video_height)/2))
        echo "clip$file_num = core.std.AddBorders(clip$file_num, left=$diff_width, right=$diff_width, top=$diff_height, bottom=$diff_height)" >> merge.vpy
        actual_height=${arr_height[$select_index]}
    fi

    echo ""
    read -p "继续添加任务吗? [Y/n]: " add_more
    if [ "$add_more" == "n" ]
    then
        break
    else
        continue
    fi
done

# 执行合并音频的命令
echo $audio_merge_command
eval $audio_merge_command

clip="clip = clip1"
for((i=2;i<=$file_num;i++))
do   
    clip="$clip + clip$i"
done
echo "$clip" >> merge.vpy
echo "clip = core.knlm.KNLMeansCL(clip, d=1, a=2, s=4, device_type='auto')" >> merge.vpy
echo "clip.set_output()" >> merge.vpy

echo -e "\n压制vpy脚本如下:"
cat merge.vpy
echo ""

sar="--sar 1:1"
read -p "是否调整sar [y/N]: " select_index
if [ "$select_index" == "y" ] # 如果调了sar 就不会再拉伸视频或者加黑边
then
    read -p "1. 8:9(默认); 2. 16:15; 3. 32:27; 4. 64:45; 请选择: " select_index
    if [ "$select_index" == "2" ]
    then
        sar="--sar 16:15"
    elif [ "$select_index" == "3" ]
    then
        sar="--sar 32:27"
    elif [ "$select_index" == "4" ]
    then
        sar="--sar 64:45"
    else
        sar="--sar 8:9"
    fi
fi

if [ "$actual_height" -gt 720 ]
then
    bit_rate_2pass=2998
elif [ "$actual_height" -gt 480 ]
then
    bit_rate_2pass=1998
else
    bit_rate_2pass=1798
fi

command_1="vspipe merge.vpy - --y4m | x264 --demuxer y4m$lev --crf 21.0 --preset slow --tune film --keyint 200 --min-keyint 1 --input-depth 16 --aq-mode 3 --pass 1 $sar --slow-firstpass --stats temp.stats -o merge.pass1.264 -"
echo $command_1
eval $command_1
del_command="$del_command merge.pass1.264"

command_2="vspipe merge.vpy - --y4m | x264 --demuxer y4m$lev --preset slow --tune film --keyint 200 --min-keyint 1 --input-depth 16 --aq-mode 3 --pass 2 $sar --bitrate $bit_rate_2pass --stats temp.stats -o merge.pass2.264 -"
echo $command_2
eval $command_2
del_command="$del_command merge.pass2.264"

ffmpeg -hide_banner -loglevel quiet -i merge.mka -c copy merge.m4a
MP4Box -quiet -add merge.pass2.264 -add merge.m4a -new merge.mp4

del_command="$del_command merge.mka merge.m4a"
echo $del_command
eval $del_command

IFS=$SAVEIFS