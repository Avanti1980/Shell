#!/usr/bin/env bash

sudo mkdir /home/temp/
sudo mount ~/Softwares/MathWorks\ MATLAB\ R2018a\ Linux/R2018a_glnxa64_dvd1.iso /home/temp/
sudo /home/temp/install
sudo umount /home/temp/
sudo mount ~/Softwares/MathWorks\ MATLAB\ R2018a\ Linux/R2018a_glnxa64_dvd2.iso /home/temp/
sudo umount /home/temp/
sudo rm -rf /home/temp/
sudo cp ~/Softwares/MathWorks\ MATLAB\ R2018a\ Linux/Crack/license_standalone.lic /usr/local/MATLAB/R2018a/licenses
sudo cp ~/Softwares/MathWorks\ MATLAB\ R2018a\ Linux/Crack/R2018a/bin/glnxa64/matlab_startup_plugins/lmgrimpl/libmwlmgrimpl.so /usr/local/MATLAB/R2018a/bin/glnxa64/matlab_startup_plugins/lmgrimpl/libmwlmgrimpl.so

sudo ln -s /usr/local/MATLAB/R2018a/bin/matlab /usr/bin/matlab
