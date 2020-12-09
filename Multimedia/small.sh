#列出所有候选文件
echo 'tasks目录的所有文件如下:'
num=0
for file_path in `ls ../Tasks/*`
do
    let num+=1
    file_name=`echo $file_path | cut -d / -f 3`
    echo $num. $file_name
done

#选择要压制的文件
echo '请选择要压制的文件序号: '
read select_index
num=0
for file_path in `ls ../Tasks/*`  
do
    let num+=1
    if [ $select_index == $num ]
    then
        file_name=`echo $file_path | cut -d / -f 3`
        break
    fi
done

echo '要压制的文件是' $file_name

#获取待压制文件扩展名
file_ext=`echo $file_name | cut -d . -f 2`

echo '创建压制脚本文件'

#创建.vpy文件
echo "import vapoursynth as vs" > $file_path.vpy
echo "import sys" >> $file_path.vpy
echo "import havsfunc as haf" >> $file_path.vpy
echo "import mvsfunc as mvf" >> $file_path.vpy
echo "core = vs.get_core()" >> $file_path.vpy

if [ $file_ext == 'ts' ]
then
    echo '创建索引'
    d2vwitch $file_path
    echo "clip = core.d2v.Source(input=r'"$file_name".d2v', threads=1)" >> $file_path.vpy
    echo "clip = mvf.Depth(clip, depth=16)" >> $file_path.vpy
else
    echo "clip = core.lsmas.LWLibavSource(source=r'"$file_name"', format='yuv420p16')" >> $file_path.vpy
fi
echo "clip.set_output()" >> $file_path.vpy

echo '提取原始音频'
ffmpeg -i $file_path -c:a copy -bsf:a aac_adtstoasc -vn $file_path.vpy.m4a

echo '开始压制 请耐心等待'
vspipe $file_path.vpy - --y4m | x264 --demuxer y4m --crf 30.0 --preset fast --tune film --keyint 600 --min-keyint 1 --input-depth 16 --sar 1:1 -o $file_path.vpy.264 -

echo '压制完成 合并视频和音频'
muxer -i $file_path.vpy.264?fps=30000/1001 -i $file_path.vpy.m4a -o $file_path.crf30.mp4
