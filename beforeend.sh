#!/bin/bash
#
TESTOVL=$(mount | grep "overlayfs-root" )
if [ -z "$TESTOVL" ]; then
  exit 0
else
  /usr/bin/mount -o remount,rw /ovl/ro
  if [ $? -ne 0 ]; then
    /usr/bin/echo "ERROR: could not mount /ovl/ro in read/write mode" >> /var/log/beforeend.log
    exit 1
  else    
    /usr/bin/date>>/root/beforeend.log  
    LIST="bin etc home lib media opt root sbin  srv usr var "
    for DIRECTORY in $LIST; do
      /usr/bin/echo "Doing directory $DIRECTORY " >> /var/log/beforeend.log
      /usr/bin/rsync -avx --delete  /$DIRECTORY/ /ovl/ro/$DIRECTORY/  >> /var/log/beforeend.log
      if [ $? -ne 0 ]; then
        /usr/bin/echo "ERROR: could not rsync /ovl/ro/$DIRECTORY " >> /var/log/beforeend.log
      else
        /usr/bin/echo "Done directory $DIRECTORY" >> /var/log/beforeend.log
      fi
    done
  fi
fi
/usr/bin/date>>/var/log/beforeend.log
