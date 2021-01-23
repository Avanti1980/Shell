# xdg-mime default dde-file-manager.desktop inode/directory

# yaourt -S npm nodejs-hexo --noconfirm
sudo npm install -g hexo-cli

# vscode
# token 25072b3906f9b2d0d9c4f3f5d596e29be402ffe0
# id ba7731b55ca5bf91bbe81b2eee7665b0

# printer
sudo gpasswd -a murongxixi lp
sudo pacman -S hplip-plugin --noconfirm
sudo hp-setup

sudo systemctl enable org.cups.cupsd.service
sudo systemctl start org.cups.cupsd.service

# yaourt -Syu --aur

# 找到你热点的配置文件, 如 /etc/NetworkManager/system-connections/hotspot 然后在 [connection] 下添加 autoconnect=true  然后重启
# cd /etc/NetworkManager/system-connections/
# sudo chmod +r system-connections
# gedit hotspot
nmcli device wifi hotspot ssid murongxixi password xixi013579
nmcli device wifi connect NJU-WLAN

sudo echo HandleLidSwitch=ignore>>/etc/systemd/logind.conf 
systemctl restart systemd-logind

sudo update-grub

ffmpeg -y -i AVSEQ02-cut.ts -i Jacqueline-logo-top-left.ass -vf "scale=2*in_w:2*in_h" -filter_complex "[0][1]overlay[v]" -map "[v]" out.mp4


ffmpeg -i AVSEQ02-cut.ts -i Jacqueline-logo-top-left.ass -filter_complex "[0:0]scale=2*in_w:2*in_h[main];[main][1]overlay[v]" -map "[v]" output.mp4

ffmpeg -i AVSEQ02-cut.ts -i Jacqueline-logo-top-left.ass -filter_complex "[0:0][0:2]overlay,scale=960:540[v]" -map [v] -map 0:1 -c:v libx264 -qp 0 -c:a copy sample_ass(embed).mkv


ffmpeg -i AVSEQ02-cut.ts -vf "ass='Jacqueline-logo-top-left.ass',scale=2*in_w:2*in_h" -c:v libx264 -qp 0 -c:a copy -sn out.mp4

ffmpeg -i qingzang.ts -vf "scale=2.25*in_w:2.25*in_h" -c:v libx264 -qp 0 -c:a copy qingzang.mp4

ffmpeg -i on-the-top-of-the-east-mountain.VOB -vf "lutyuv=y=val*1.6" -c:v libx264 -qp 0 on-the-top-of-the-east-mountain.mp4

增大音量
ffmpeg -i input.wav -af 'volume=2' output.wav

https://www.tecmint.com/configure-network-connections-using-nmcli-tool-in-linux/
https://wiki.archlinux.org/index.php/NetworkManager
nmcli device wifi list
nmcli device wifi connect <wifi-name> password <password> 

/etc/NetworkManager/system-connections
chmod +r +w都不够

查看可用的链接
nmcli connection

打开/关闭
nmcli connection up/down Hotspot/TP-LINK_DE0E02/NJU-WLAN

nmcli device wifi connect CMCC-Q2aM password hxgwfs2y

sshfs murongxixi@114.212.84.119:/home/murongxixi/Videos /home/murongxixi/Public

file 'input1.mkv'
file 'input2.mkv'
file 'input3.mkv'
ffmpeg -f concat -i filelist.txt -c copy output.mkv 
