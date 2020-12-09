#!/usr/bin/env bash

folder=$(date +%Y-%m)

if [ -d "/home/murongxixi/.local/lib/wine-wechat/default/drive_c/users/murongxixi/我的文档/WeChat Files/murong-xixi/FileStorage/File/$folder" ]; then
    rsync -av "/home/murongxixi/.local/lib/wine-wechat/default/drive_c/users/murongxixi/我的文档/WeChat Files/murong-xixi/FileStorage/File/$folder" /home/murongxixi/Softwares/Wechat/
    rm -rf "/home/murongxixi/.local/lib/wine-wechat/default/drive_c/users/murongxixi/我的文档/WeChat Files/murong-xixi/FileStorage/File/$folder"
fi
