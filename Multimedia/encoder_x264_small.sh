for i in `ls ../tasks/*.vpy`
    do    
        echo "$i"
        vspipe "$i" - --y4m | x264 --demuxer y4m --crf 30.0 --preset fast --tune film --keyint 600 --min-keyint 1 --input-depth 16 --sar 1:1 -o "$i.264" -
        muxer -i "$i.264"?fps=30000/1001 -i "$i.m4a" -o "$i.small.mp4"
    done 