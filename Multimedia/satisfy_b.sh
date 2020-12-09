# 检查某一目录下的视频是否符合b站二压要求

SAVEIFS=$IFS
IFS=`echo -en "\n\b"`

video_list=`find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(ts|mp4|mkv|m2ts|mpg|mpeg|rmvb|rm|vob|avi|wmv|flv|mts)"`

for file in $video_list
do
    file_name=`echo $file | cut -d / -f 2`
    echo -e "\n当前正在处理$file_name"

    video_muxer_format=`mediainfo --Inform="General;%Format%" "$file_name"` # 封装格式
    video_encoder_format=`mediainfo --Inform="Video;%Format%" "$file_name"` # 编码格式
    video_bit_rate=`mediainfo --Inform="Video;%BitRate%" "$file_name"` # 码率
    video_width=`mediainfo --Inform="Video;%Width%" "$file_name"`
    video_height=`mediainfo --Inform="Video;%Height%" "$file_name"`
    video_dar=`mediainfo --Inform="Video;%DisplayAspectRatio%" "$file_name"`
    if [ "$video_dar" == "1.333" ]
    then
        video_dar="4:3"
    elif [ "$video_dar" == "1.778" ]
    then
        video_dar="16:9"
    fi

    video_satisfy=0

    if [ "$video_encoder_format" == "AVC" ] && [ "$video_height" -gt 720 ] && [ "$video_bit_rate" -lt 3000000 ]
    then
        video_satisfy=1
    fi

    if [ "$video_encoder_format" == "AVC" ] && [ "$video_height" -gt 480 ] && [ "$video_bit_rate" -lt 2000000 ]
    then
        video_satisfy=1
    fi

    echo $video_encoder_format $video_height $video_bit_rate
    if [ "$video_encoder_format" == "AVC" ] && [ "$video_height" -lt 481 ] && [ "$video_bit_rate" -lt 1800000 ]
    then
        video_satisfy=1
    fi

    audio_format=`mediainfo --Inform="Audio;%Format%" "$file_name"` # AAC or AC3 or MPEG Audio Layer2/3
    audio_bit_rate=`mediainfo --Inform="Audio;%BitRate%" "$file_name"`
    audio_channels=`mediainfo --Inform="Audio;%Channel(s)%" "$file_name"`

    audio_satisfy=0
    if [ "$audio_format" == "AAC" ] && [ "$audio_bit_rate" -lt 192000 ] && [ "$audio_channels" -lt 3 ]
    then
        audio_satisfy=1
    fi

    echo "视频封装方式<$video_muxer_format> 编码方式<$video_encoder_format> 码率<$video_bit_rate> 分辨率<$video_width*$video_height> 显示比例$video_dar"

    echo "音频格式<$audio_format> 码率<$audio_bit_rate> 通道数<$audio_channels>"

    arr=(不 已经)

    echo "视频${arr[$video_satisfy]}满足b站要求"
    echo "音频${arr[$audio_satisfy]}满足b站要求"

done

IFS=$SAVEIFS
