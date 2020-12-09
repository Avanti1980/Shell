#!/usr/bin/env bash

cd "/home/murongxixi/.deepinwine/Deepin-TIM/drive_c/users/murongxixi/My Documents/Tencent Files/961765117/FileRecv/"

if [ -n "$(find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(ass)")" ]; then
    mv ./*.ass /home/murongxixi/Softwares/Tim/
fi

if [ -n "$(find . -maxdepth 1 -regextype posix-extended -iregex ".*\.(xlsx)")" ]; then
    mv ./*.xlsx /home/murongxixi/Softwares/Tim/
fi