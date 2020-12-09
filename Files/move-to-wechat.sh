#!/usr/bin/env bash

folder=$(date +%Y-%m)

if [ ! -d "/home/murongxixi/.local/lib/wine-wechat/default/drive_c/users/murongxixi/我的文档/WeChat Files/murong-xixi/FileStorage/File/$folder" ]; then
    echo "目标文件夹不存在 新建文件夹"
    mkdir "/home/murongxixi/.local/lib/wine-wechat/default/drive_c/users/murongxixi/我的文档/WeChat Files/murong-xixi/FileStorage/File/$folder"
fi

if [ -n "$(find /home/murongxixi/Desktop/ -maxdepth 1 -regextype posix-extended -iregex ".*\.(png|jpg|pdf)")" ]; then
    mv /home/murongxixi/Desktop/* "/home/murongxixi/.local/lib/wine-wechat/default/drive_c/users/murongxixi/我的文档/WeChat Files/murong-xixi/FileStorage/File/$folder/"
fi
