#!/bin/bash
#doRPI.sh 

#Update the system
apt-get update
apt-get -y full-upgrade

rpi-update

#Install vim
apt-get -y install vim

apt-get -y purge "pulseaudio*"

#Remove dhcpcd
apt-get -y remove dhcpcd5 isc-dhcp-client pump
apt-get -y purge dhcpcd5 isc-dhcp-client pump

#Disable IPV6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >>/etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >>/etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >>/etc/sysctl.conf
echo "net.ipv6.conf.eth0.disable_ipv6 = 1" >>/etc/sysctl.conf
echo "# Local module settings" > /etc/modprobe.d/blacklist-IPV6.conf
echo "blacklist ipv6" >> /etc/modprobe.d/blacklist-IPV6.conf


curl https://gist.githubusercontent.com/lucacan/64318b72d3e3d2b33a2d89423fa166ef/raw/c94ef2549c326989e9a8528f6d066613d8314407/ro-root.sh -o ro-root.sh
chmod +x ro-root.sh
cp ro-root.sh /bin/ro-root.sh

#Test if exist and then backup /boot/config.txt 
if [ ! -f /boot/config.txt ]; then
    cp -v /boot/config.txt /boot/config.orig.txt
fi

TESTCFGTXT=$(cat /boot/config.txt |$GREP 'dtoverlay=disable-bt')
if [ -z "$TESTCFGTXT" ]; then
  sed -i '/# Some settings may impact device functionality./a ramfsaddr=-1' /boot/config.txt
  sed -i '/# Some settings may impact device functionality./a ramfsfile=initrd' /boot/config.txt
  sed -i '/# Some settings may impact device functionality./a initramfs initrd followkernel' /boot/config.txt
  # Disable Wifi

dtoverlay=pi3-disable-wifi
 PI4=$( cat /sys/firmware/devicetree/base/model | grep 'Pi 4'
 PI3=$( cat /sys/firmware/devicetree/base/model | grep 'Pi 3'
if [ -z "$PI4" ]; then
  sed -i '/\[all\]/a dtoverlay=disable-wifi' /boot/config.txt
fi
if [ -z "$PI3" ]; then
  sed -i '/\[all\]/a dtoverlay=pi3-disable-wifi' /boot/config.txt
fi
  sed -i '/\[all\]/a # Disable Wifi' /boot/config.txt
  #Disable Bluetooth
  sed -i '/\[all\]/a dtoverlay=disable-bt' /boot/config.txt
  sed -i '/\[all\]/a # Disable Bluetooth' /boot/config.txt
fi

systemctl disable hciuart.service
systemctl disable bluealsa.service
systemctl disable bluetooth.service

dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove

#Test if exist and then create backup /boot/cmdline.orig.txt
if [ ! -f /boot/cmdline.orig.txt ]; then
  cp -v /boot/cmdline.txt /boot/cmdline.orig.txt
  cp -v /boot/cmdline.txt /boot/cmdline.overlay.txt
  sed -i 's/rootwait/rootwait ro init=\/bin\/ro-root.sh /g' /boot/cmdline.overlay.txt
fi

echo "[Unit]">/etc/systemd/system/beforeend.service
echo "Description=Script to execute before end">>/etc/systemd/system/beforeend.service
echo "DefaultDependencies=no">>/etc/systemd/system/beforeend.service
echo "Before=shutdown.target reboot.target halt.target">>/etc/systemd/system/beforeend.service
echo "# This works because it is installed in the target and will be">>/etc/systemd/system/beforeend.service
echo "# executed before the target state is entered">>/etc/systemd/system/beforeend.service
echo "[Service]">>/etc/systemd/system/beforeend.service
echo "Type=oneshot">>/etc/systemd/system/beforeend.service
echo "ExecStart=/root/beforeend.sh">>/etc/systemd/system/beforeend.service
echo "[Install]">>/etc/systemd/system/beforeend.service
echo "WantedBy=halt.target reboot.target shutdown.target">>/etc/systemd/system/beforeend.service

echo '#!/bin/bash'>/root/beforeend.sh
echo '#'>>/root/beforeend.sh
echo 'TESTOVL=$(mount | grep "overlayfs-root" )'>>/root/beforeend.sh
echo 'if [ -z "$TESTOVL" ]; then'>>/root/beforeend.sh
echo '  exit 0'>>/root/beforeend.sh
echo 'else'>>/root/beforeend.sh
echo '  /usr/bin/mount -o remount,rw /ovl/ro'>>/root/beforeend.sh
echo '  if [ $? -ne 0 ]; then'>>/root/beforeend.sh
echo '    /usr/bin/echo "ERROR: could not mount /ovl/ro in read/write mode" >> /var/log/beforeend.log'>>/root/beforeend.sh
echo '    exit 1'>>/root/beforeend.sh
echo '  else    '>>/root/beforeend.sh
echo '    /usr/bin/date>>/root/beforeend.log  '>>/root/beforeend.sh
echo '    LIST="bin etc home lib media opt root sbin  srv usr var "'>>/root/beforeend.sh
echo '    for DIRECTORY in $LIST; do'>>/root/beforeend.sh
echo '      /usr/bin/echo "Doing directory $DIRECTORY " >> /var/log/beforeend.log'>>/root/beforeend.sh
echo '      /usr/bin/rsync -avx --delete  /$DIRECTORY/ /ovl/ro/$DIRECTORY/  >> /var/log/beforeend.log'>>/root/beforeend.sh
echo '      if [ $? -ne 0 ]; then'>>/root/beforeend.sh
echo '        /usr/bin/echo "ERROR: could not rsync /ovl/ro/$DIRECTORY " >> /var/log/beforeend.log'>>/root/beforeend.sh
echo '      else'>>/root/beforeend.sh
echo '        /usr/bin/echo "Done directory $DIRECTORY" >> /var/log/beforeend.log'>>/root/beforeend.sh
echo '      fi'>>/root/beforeend.sh
echo '    done'>>/root/beforeend.sh
echo '  fi'>>/root/beforeend.sh
echo 'fi'>>/root/beforeend.sh
echo '/usr/bin/date>>/var/log/beforeend.log'>>/root/beforeend.sh
chmod 700 /root/beforeend.sh

echo '\#!/bin/bash'>/root/overlayOn.sh
echo 'cp -a /boot/cmdline.overlay.txt /boot/cmdline.txt'>>/root/overlayOn.sh
echo '#reboot '>>/root/overlayOn.sh
chmod 700 /root/overlayOn.sh

echo '#!/bin/bash'>/root/overlayOff.sh
echo 'cp -a /boot/cmdline.orig.txt /boot/cmdline.txt'>>/root/overlayOff.sh
echo '#reboot '>>/root/overlayOn.sh
chmod 700 /root/overlayOff.sh

mkdir /ovl/
mkinitramfs -o /boot/initrd
/root/overlayOn.sh
systemctl enable beforeend
