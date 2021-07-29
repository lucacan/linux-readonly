#!/bin/bash
#Script used to prepare SD for Raspberry PI
##
##COMMANDS
ECHO="/usr/bin/echo"
SHA256SUM="/usr/bin/sha256sum"
GREP="/usr/bin/grep"
SYNC="/usr/bin/sync"
FDISK="/usr/sbin/fdisk"
MOUNT="/usr/bin/mount"
UMOUNT="/usr/bin/umount"
DD="/usr/bin/dd"
UNZIP="/usr/bin/unzip"
E2LABEL="/usr/sbin/e2label"
MKDIR="/usr/bin/mkdir"
RMDIR="/usr/bin/rmdir"
SLEEP="/usr/bin/sleep"
TOUCH="/usr/bin/touch"
CAT="/usr/bin/cat"
CP="/usr/bin/cp"
CHMOD="/usr/bin/chmod"
##PARAMETERS
source ./doStartPC.config
ISO_LAST_NAME="${ISO_LAST##*/}"
ISO_LAST_NAME_NOEXT="${ISO_LAST_NAME%\.*}"
#
#Test parameter
if [ -z "$ISO_LAST" ]; then
  $ECHO "Missed configuration File!"
   exit 1
fi

#Test parameter
if [ $# -lt 1 ]; then
  $ECHO "Missed target disk!"
   exit 1
fi
DISKTOWRITE=$1

#Test if exist and then download ISO
if [ ! -f ./"$ISO_LAST_NAME" ]; then
  $ECHO "File $ISO_LAST_NAME not present, download it!"
  wget $ISO_LAST
fi

#Test sha256
TESTSHA=$($SHA256SUM $ISO_LAST_NAME | $GREP $ISO_SHA256 )

if [ -z "$TESTSHA" ]; then
  $ECHO "SHA256 not correct!"
  exit 1
else
  $ECHO
  $ECHO $TESTSHA
  $ECHO "(1) Sha test verified!"
  $ECHO
fi

      $UNZIP $ISO_LAST_NAME



      #Check disk to write
      FDISK_OUT=$(sudo $FDISK -l |$GREP "Disk $DISKTOWRITE")
      if [ -z "$FDISK_OUT" ]; then
        $ECHO "Disk not present!"
        exit 1
      fi

      for PART in $($FDISK -l $DISKTOWRITE |grep ^$DISKTOWRITE | awk '{ FS=" " } { print $1}')
      do
        $UMOUNT $PART
      done

      read -p "If the partition of $FDISK_OUT are unmount and we can continue press Y :" -n 1 -r
        if [[ $REPLY =~ ^[Y]$ ]]; then
    $ECHO 
    $ECHO "(2) Disk tested and partition unmounted"
    $ECHO 
  else
    $ECHO
    exit 1
  fi


$ECHO "the disk where to write is :"
$ECHO $FDISK_OUT
read -p "If You are sure press Y? " -n 1 -r
if [[ $REPLY =~ ^[Y]$ ]]; then
  $ECHO
  read -p "If You are sure to write $FDISK_OUT press Y :" -n 1 -r
  if [[ $REPLY =~ ^[Y]$ ]]; then
    $ECHO
    $ECHO
    $DD if=$ISO_LAST_NAME_NOEXT.img of=$DISKTOWRITE bs=256M status=progress
    $ECHO "Start copy iso image"
  else
    $ECHO
    exit 1
  fi
else
  $ECHO
  exit 1
fi
read -p "If the data are correctrly copyed and we can continue, press Y :" -n 1 -r
  if [[ $REPLY =~ ^[Y]$ ]]; then
    $SYNC
    $ECHO 
    $ECHO "(3) ISO copied on SD"
    $ECHO 
  else
    $ECHO
    exit 1
  fi

$SYNC
 

APPODIR="/mnt/myappodir"
$MKDIR -p $APPODIR

for PART in $($FDISK -l $DISKTOWRITE |grep ^$DISKTOWRITE | awk '{ FS=" " } { print $1}')
do
  $ECHO 
  $ECHO $PART
  PART1=$($E2LABEL $PART 2>/dev/null | $GREP 'boot')
  PART2=$($E2LABEL $PART 2>/dev/null | $GREP 'rootfs')
  if [ ! -z "$PART1" ]; then
    # Part 1 $MOUNT
    $MOUNT $PART $APPODIR
    #Scrittura "ssh"
    $ECHO 
    $ECHO "Create file ssh"
    $TOUCH "$APPODIR/ssh"
    #scrittura wifi
    $ECHO 
    $ECHO "Create file wpa_supplicant.conf"
    WPASF=$APPODIR"/wpa_supplicant.conf"
    $ECHO "country=IT" > $WPASF
    $ECHO "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev">>$WPASF
    $ECHO "update_config=1">>$WPASF
    $ECHO "network={">>$WPASF
    $ECHO " scan_ssid=1">>$WPASF
    $ECHO " ssid='$WIFI_SSID'">>$WPASF
    $ECHO " psk='$WIFI_PASSWORD'">>$WPASF
    $ECHO " key_mgmt=WPA-PSK">>$WPASF
    $ECHO "}">>$WPASF
    $CAT $WPASF
    $SLEEP 3
    $UMOUNT $PART 
  fi 


 if [ ! -z "$PART2" ]; then
    # Part 2 $MOUNT
    $MOUNT $PART $APPODIR
    #Scrittura dhcpcd non fatta
    #Scrittura /etc/network/
    FILENTERFACE="$APPODIR/etc/network/interfaces"
    $ECHO "FILEINTERFECE $FILENTERFACE"
    $ECHO "APPODIR $APPODIR"
    EXISTETH=$($CAT $FILENTERFACE | $GREP 'eth0')
    if [ -z "$EXISTETH" ]; then   
      $ECHO 
      $ECHO "Update file $FILENTERFACE"
      $ECHO "" >> $FILENTERFACE    
      $ECHO "auto eth0" >> $FILENTERFACE
      $ECHO "allow-hotplug eth0" >> $FILENTERFACE
      $ECHO "iface eth0 inet static" >> $FILENTERFACE
      $ECHO "address $WIRED_IP" >> $FILENTERFACE
      $ECHO "netmask $WIRED_MASK" >> $FILENTERFACE
      $ECHO "gateway $WIRED_GW" >> $FILENTERFACE
    fi
    $CP doRPI.sh $APPODIR/root/doRPI.sh
    $ECHO $CHMOD 700 $APPODIR/root/doRPI.sh
    $CHMOD 700 $APPODIR/root/doRPI.sh
    $CAT $FILENTERFACE
    ls $APPODIR   
    $SLEEP 3
    $UMOUNT $PART 
  fi 

done

   $ECHO "SSD ready to use"
