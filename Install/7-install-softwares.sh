# 显卡驱动
pacman -S intel-ucode intel-media-driver intel-compute-runtime
pacman -S libva-vdpau-driver mesa-vdpau libvdpau-va-gl vdpauinfo
pacman -S nvidia-dkms nvidia-utils opencl-nvidia
pacman -S bumblebee primus
systemctl enable bumblebeed.service
usermod -aG bumblebee avanti

# 常用工具
pacman -S betterlockscreen                                              # 锁屏
pacman -S curl wget youtube-dl transmission-qt                          # 下载
pacman -S v2ray qv2ray-dev-git qv2ray-plugin-ssr-dev-git proxychains-ng # 科学上网
pacman -S geogebra                                                      # 画图
pacman -S deepin-screen-recorder                                        # 截图
pacman -S deepin-image-viewer                                           # 看图
pacman -S deepin-picker                                                 # 取色
pacman -S baidupcs-go-git baidunetdisk-bin                              # 度盘
pacman -S electronic-wechat                                             # 微信

pacman -S texlive-most texlive-lang
pacman -S perl-log-log4perl perl-yaml-tiny perl-file-homedir perl-unicode-linebreak

pacman -S evince pdftk

pacman -S typora pandoc pandoc-citeproc pandoc-crossref princexml

pacman -S hunspell hunspell-en_AU hunspell-en_CA hunspell-en_GB hunspell-en_US

pacman -S hugo npm

pacman -S ghostscript inkscape imagemagick krita                                    # 图片
pacman -S mpv mpv-bash-completion-git vlc gpac mediainfo-gui mkvtoolnix-gui aegisub # 视频
pacman -S audacious mpg123 spek-git                                                 # 音乐
pacman -S shntool mac                                                               # 分割cue
# shntool split -f example.cue -t %p\ %n\ %t -o flac example.ape 将example.ape分割 同时转成flac格式

pacman -S jupyterlab python-sympy python-pillow
pacman -S python-scikit-learn python-numba python-cvxopt python-matplotlib
pacman -S python-tensorflow-opt-cuda python-pytorch-opt-cuda tensorboard

pacman -S octave octave-forge julia

pacman -S graphviz xdot dot2tex

pacman -S clang shfmt autopep8 yapf

pacman -S hplip hplip-plugin system-config-printer
