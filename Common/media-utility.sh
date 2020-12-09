# 自己实现的一个函数库合集 供其他脚本调用

function process_audio() { # 该函数返回处理后的音频文件名
    audio_format=$(mediainfo --Inform="Audio;%Format%" "$1")
    case "$2" in
    "extract") # 直接提取
        case "$audio_format" in
        "AAC")
            ffmpeg -hide_banner -loglevel quiet -i "$1" -vn -c:a copy -bsf:a aac_adtstoasc "$1.m4a"
            echo "$1.m4a"
            ;;
        "AC-3" | "AC-3AC-3" | "AC-3MPEG Audio") #AC-3AC-3是ffmpeg的bug 6声道的AC3的音频都会重复显示两遍
            ffmpeg -hide_banner -loglevel quiet -i "$1" -vn -c:a copy "$1.ac3"
            echo "$1.ac3"
            ;;
        "MPEG Audio" | "MPEG AudioMPEG Audio")
            audio_format_profile=$(mediainfo --Inform="Audio;%Format_Profile%" "$1")
            if [ "${audio_format_profile:0:7}" == "Layer 3" ]; then
                ffmpeg -hide_banner -loglevel quiet -i "$1" -vn -c:a copy "$1.mp3"
                echo "$1.mp3"
            elif [ "${audio_format_profile:0:7}" == "Layer 2" ]; then
                ffmpeg -hide_banner -loglevel quiet -i "$1" -vn -c:a copy "$1.mp2"
                echo "$1.mp2"
            fi
            ;;
        esac
        ;;
    "transcode") # 转码
        ffmpeg -hide_banner -loglevel quiet -i "$1" -vn -c:a aac -ar 48000 -b:a 192k "$1.m4a"
        echo "$1.m4a"
        ;;
    esac
}

function show_info() {
    ffprobe -hide_banner "$1"
}

function satisfy_b() {
    case $2 in
    "video") # 检测视频是否符合b站要求
        video_encoder_format=$(mediainfo --Inform="Video;%Format%" "$1") # 编码格式
        if [ "$video_encoder_format" == "AVC" ]; then
            video_bit_rate=$(mediainfo --Inform="Video;%BitRate%" "$1") # 码率
            video_height=$(mediainfo --Inform="Video;%Height%" "$1")
            if [ "$video_height" -gt 720 -a "$video_bit_rate" -lt 3000000 ] || [ "$video_height" -gt 480 -a "$video_bit_rate" -lt 2000000 ] || [ "$video_height" -lt 481 -a "$video_bit_rate" -lt 1800000 ]; then
                return 1
            fi
        else
            return 0
        fi
        ;;
    "audio") # 检测音频是否符合b站要求
        audio_format=$(mediainfo --Inform="Audio;%Format%" "$1") # AAC or AC3 or MPEG Audio Layer2/3
        audio_bit_rate=$(mediainfo --Inform="Audio;%BitRate%" "$1")
        if [ "$audio_format" == "AAC" ]; then
            return 1
        fi
        return 0
        ;;
    esac
}

# config_transcode
# $1 字符串 要处理的视频文件名
# $2 y/n 是否投b站
# $3 字符串 "no_subtitle"将跳过选择字幕
# $4 字符串 "x264"将跳过选择编码器
# $5 字符串 "default_bit_rate"将跳过码率设置
# $6 字符串 非空将跳过x264的crf参数设置
# $7 字符串 非空将跳过x265的crf参数设置
function config_transcode() { # 该函数只配置 vpy文件 和 命令列表
    del="rm \"$1.vpy\"" # 创建删除命令

    echo -e "\n开始设置vpy脚本"
    echo -e "import vapoursynth as vs\nimport sys\nimport havsfunc as haf\nimport mvsfunc as mvf\ncore = vs.get_core()" >"$1.vpy"

    video_muxer_format=$(mediainfo --Inform="General;%Format%" "$1") # 封装格式
    video_encoder_format=$(mediainfo --Inform="Video;%Format%" "$1") # 编码格式
    if [ "$video_encoder_format" == "MPEG Video" ] && [ "$video_muxer_format" == "MPEG-TS" -o "$video_muxer_format" == "MPEG-PS" ]; then
        d2vwitch "$1"
        echo -e "clip = core.d2v.Source(input=r'$1.d2v', threads=1)\nclip = mvf.Depth(clip, depth=16)" >>"$1.vpy"
        del="$del \"$1.d2v\""
    else
        echo "clip = core.lsmas.LWLibavSource(source=r'$1', format='yuv420p16')" >>"$1.vpy"
        del="$del \"$1.lwi\""
    fi

    if [ "$video_fps" == "50.000" -o "$video_fps" == "60.000" ]; then
        video_fps=${video_fps%.*} #取整
        echo "clip = haf.ChangeFPS(clip, (($video_fps/2)), 1)" >>"$1.vpy"
    fi

    video_scantype=$(mediainfo --Inform="Video;%ScanType%" "$1") # Interlaced or Progressive
    video_width=$(mediainfo --Inform="Video;%Width%" "$1")
    video_height=$(mediainfo --Inform="Video;%Height%" "$1")
    video_dar=$(mediainfo --Inform="Video;%DisplayAspectRatio%" "$1")
    if [ "$video_dar" == "1.333" ]; then
        video_dar1=4
        video_dar2=3
    elif [ "$video_dar" == "1.778" ]; then
        video_dar1=16
        video_dar2=9
    fi

    if [ -n "$video_scantype" ] && [ "$video_scantype" != "Progressive" ]; then
        video_scanorder=$(mediainfo --Inform="Video;%ScanOrder%" "$1") # TFF or BFF
        if [ "$video_scanorder" == "TFF" ]; then
            echo "clip = haf.QTGMC(clip, Preset='Slow', FPSDivisor=2, TFF=True)" >>"$1.vpy"
        else
            echo "clip = haf.QTGMC(clip, Preset='Slow', FPSDivisor=2, TFF=False)" >>"$1.vpy"
        fi
    fi

    echo "clip = core.knlm.KNLMeansCL(clip, d=1, a=2, s=4, device_type='auto')" >>"$1.vpy"

    if [ "$3" != "no_subtitle" ]; then
        read -p "是否添加字幕 [y/N]: " add_subtitle
        if [ "$add_subtitle" == "y" ]; then
            ext="ass|srt"
            list_file $ext
            subtitle_name=$(select_file $ext)
            echo "选择了文件 [ $subtitle_name ]"
            echo "clip = core.sub.TextFile(clip, file=r'$subtitle_name')" >>"$1.vpy"
        fi
    fi

    echo "clip.set_output()" >>"$1.vpy"

    echo -e "\n压制vpy脚本如下:"
    cat "$1.vpy"

    if [ "$4" == "x264" ]; then
        select_encoder=1
    else
        arr_function=(x264 x265 x264_x265)
        select_from_arr "${arr_function[*]}"
        select_encoder=$?
        echo "选择了 [${arr_function[(($select_encoder - 1))]}]"
    fi

    ((sar1 = $video_dar1 * $video_height))
    ((sar2 = $video_dar2 * $video_width))
    sar="--sar $sar1:$sar2"

    crf264="--crf 21.5"
    crf265="--crf 21.5"
    keyint=250
    if [ "$2" == "y" ]; then # 只有投b站才2pass 才需要设置码率 才用flv封装
        if [ "$video_height" -gt 720 ]; then
            bit_rate_2pass=3080
        elif [ "$video_height" -gt 480 ]; then
            bit_rate_2pass=2040
        else
            bit_rate_2pass=1840
        fi

        if [ "$5" != "default_bit_rate" ]; then
            read -p "默认码率为 3080(1080p) 2040(720p) 1840(480p) 是否手动设置码率? [y/N]: " bit_rate_setting
            if [ "$bit_rate_setting" == "y" ]; then
                read -p "请输入码率: " bit_rate_2pass
            fi
        fi

        echo "vspipe \"$1.vpy\" - --y4m \| x264 --demuxer y4m $crf264 --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 --pass 1 --slow-firstpass --stats temp.stats -o \"$1.pass1.264\" -" >>command_list

        echo "vspipe \"$1.vpy\" - --y4m \| x264 --demuxer y4m --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 --pass 2 --bitrate $bit_rate_2pass --stats temp.stats -o \"$1.264\" -" >>command_list

        del="$del \"$1.pass1.264\" temp.stats*"
        echo $del >>command_list
        return 1
    else # crf模式
        case $select_encoder in
        "1")
            if [ -n "$6" ]; then
                crf264="--crf $6"
            else
                read -p "请输入x264的crf参数(默认21.5): " input_crf
                crf264="--crf $input_crf"
            fi

            echo "vspipe \"$1.vpy\" - --y4m \| x264 --demuxer y4m $crf264 --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 -o \"$1.264\" -" >>command_list
            ;;
        "2")
            if [ -n "$7" ]; then
                crf265="--crf $7"
            else
                read -p "请输入x265的crf参数(默认21.5): " input_crf
                crf265="--crf $input_crf"
            fi

            echo "vspipe \"$1.vpy\" - --y4m \| x265 --y4m --preset slow $crf265 --ctu 32 --min-cu-size 8 --max-tu-size 32 --tu-intra-depth 2 --tu-inter-depth 2 --me 3 --subme 4 --merange 44 --no-rect --no-amp --max-merge 3 --temporal-mvp --no-early-skip --rskip --rdpenalty 0 --no-tskip --no-tskip-fast --no-strong-intra-smoothing --no-lossless --no-cu-lossless --no-constrained-intra --no-fast-intra --no-open-gop --no-temporal-layers --keyint 360 --min-keyint 1 --scenecut 40 --rc-lookahead 72 --lookahead-slices 4 --bframes 6 --bframe-bias 0 --b-adapt 2 --ref 4 --limit-refs 2 --limit-modes --weightp --weightb --aq-mode 1 --qg-size 16 --aq-strength 1.0 --cbqpoffs -3 --crqpoffs -3 --rd 4 --psy-rd 2.0 --psy-rdoq 3.0 --rdoq-level 2 --deblock -2:-2 --no-sao --no-sao-non-deblock --pbratio 1.2 --qcomp 0.6 --input-depth 16 $sar -o \"$1.hevc\" -" >>command_list
            ;;
        "3")
            if [ -n "$6" ]; then
                crf264="--crf $6"
            else
                read -p "请输入x264的crf参数(默认21.5): " input_crf
                crf264="--crf $input_crf"
            fi

            if [ -n "$7" ]; then
                crf265="--crf $7"
            else
                read -p "请输入x265的crf参数(默认21.5): " input_crf
                crf265="--crf $input_crf"
            fi

            echo "vspipe \"$1.vpy\" - --y4m \| x264 --demuxer y4m $crf264 --preset slow --tune film --keyint $keyint --min-keyint 1 --input-depth 16 $sar --aq-mode 3 -o \"$1.264\" -" >>command_list

            echo "vspipe \"$1.vpy\" - --y4m \| x265 --y4m --preset slow $crf265 --ctu 32 --min-cu-size 8 --max-tu-size 32 --tu-intra-depth 2 --tu-inter-depth 2 --me 3 --subme 4 --merange 44 --no-rect --no-amp --max-merge 3 --temporal-mvp --no-early-skip --rskip --rdpenalty 0 --no-tskip --no-tskip-fast --no-strong-intra-smoothing --no-lossless --no-cu-lossless --no-constrained-intra --no-fast-intra --no-open-gop --no-temporal-layers --keyint 360 --min-keyint 1 --scenecut 40 --rc-lookahead 72 --lookahead-slices 4 --bframes 6 --bframe-bias 0 --b-adapt 2 --ref 4 --limit-refs 2 --limit-modes --weightp --weightb --aq-mode 1 --qg-size 16 --aq-strength 1.0 --cbqpoffs -3 --crqpoffs -3 --rd 4 --psy-rd 2.0 --psy-rdoq 3.0 --rdoq-level 2 --deblock -2:-2 --no-sao --no-sao-non-deblock --pbratio 1.2 --qcomp 0.6 --input-depth 16 $sar -o \"$1.hevc\" -" >>command_list
            ;;
        esac
        echo $del >>command_list
        return $select_encoder
    fi
}

function merge_av() {
    case $2 in
    "1")
        echo "MP4Box -quiet -add \"$1.264\" -add \"$3\" -new \"$1.mp4\"" >>command_list
        echo "rm \"$1.264\" \"$3\"" >>command_list
        ;;
    "2")
        echo "MP4Box -quiet -add \"$1.hevc\" -add \"$3\" -new \"$1.mp4\"" >>command_list
        echo "rm \"$1.hevc\" \"$3\"" >>command_list
        ;;
    "3")
        echo "MP4Box -quiet -add \"$1.264\" -add \"$3\" -new \"$1.mp4\"" >>command_list
        echo "MP4Box -quiet -add \"$1.hevc\" -add \"$3\" -new \"$1.265.mp4\"" >>command_list
        echo "rm \"$1.264\" \"$1.hevc\" \"$3\"" >>command_list
        ;;
    esac
}

function execute_command() {
    echo -e "\n所有命令如下:"
    cat command_list

    echo -e "\n开始压制 请稍等"
    while read command_line; do
        if [ -z "$command_line" -o ${command_line:0:1} == "#" ]; then
            continue
        fi
        echo $command_line
        eval $command_line
    done <command_list
    rm command_list
}

function frame2time() {

    hour=$(($1 / 90000))
    temp=$(($1 % 90000))
    minute=$(($temp / 1500))
    temp=$(($1 % 1500))
    second=$(($temp / 25))
    temp=$(($1 % 25))
    msec=$(($temp * 40))
    start_time="$hour:$minute:$second.$msec"

    hour=$(($trim_end / 90000))
    temp=$(($trim_end % 90000))
    minute=$(($temp / 1500))
    temp=$(($trim_end % 1500))
    second=$(($temp / 25))
    temp=$(($trim_end % 25))
    msec=$(($temp * 40))
    end_time="$hour:$minute:$second.$msec"

    code="ffmpeg -i $3.VOB -vn -c:a aac -ar 48000 -b:a 192k -ss $start_time -to $end_time $3.m4a"
    #code="ffmpeg -i $3.vob -c copy -ss $start_time -to $end_time $3-cut.vob"
    echo $code
    eval $code
}
