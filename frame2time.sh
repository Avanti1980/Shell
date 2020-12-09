sec=$(($1 * 1001 / 30000))
msec=$(($1 * 1001 % 30000))
msec=$(($msec / 3))
min=$(($sec / 60))
sec=$(($sec % 60))
hour=$(($min / 60))
min=$(($min % 60))
echo clip_start=$hour:$min:$sec.$msec

# 第四部分的结束帧数也是整集的结束帧数 换算成<时:分:秒.毫秒>的格式
sec=$(($2 * 1001 / 30000))
msec=$(($2 * 1001 % 30000))
msec=$(($msec / 3))
min=$(($sec / 60))
sec=$(($sec % 60))
hour=$(($min / 60))
min=$(($min % 60))
echo clip_end=$hour:$min:$sec.$msec