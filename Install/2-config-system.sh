# 安装内核和驱动
pacman -S linux linux-headers linux-firmware

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime # 设置时区
hwclock --systohc                                       # 硬件时间设置 默认为UTC时间

# 本地化
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen                              # 生成本地化文件/etc/locale.gen
echo LANG=zh_CN.UTF-8 >/etc/locale.conf # 设置系统默认语言为简体中文

echo avanti-xps17 >/etc/hostname # 设置主机名
echo 127.0.0.1 localhost >/etc/hosts
echo ::1 localhost >>/etc/hosts

# 安装引导
pacman -S grub os-prober efibootmgr

# 在/efi/EFI分区下创建GRUB/grubx64.efi文件
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB

# 生成配置文件 同时自动找回win10的启动文件
grub-mkconfig -o /boot/grub/grub.cfg

passwd # 设置root密码

sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
useradd -m -g wheel avanti # 添加用户到wheel组

passwd avanti # 设置普通账户的密码
