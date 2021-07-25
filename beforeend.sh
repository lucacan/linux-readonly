#!/bin/bash
MOUNT=/usr/bin/mount
DATE=/usr/bin/date
RSYNC=/usr/bin/rsync
ECHO=/usr/bin/echo
#
$MOUNT -o remount,rw /ovl/ro
if [ $? -ne 0 ]; then
	$ECHO "ERROR: could not mount /ovl/ro in read/write mode" >> /var/log/beforeend.log
	exit 1
else    
	$DATE>>/root/beforeend.log  
	LIST="bin etc home lib media opt root sbin  srv usr var "
	for DIRECTORY in $LIST; do
		$ECHO "Doing directory $DIRECTORY " >> /var/log/beforeend.log
		$RSYNC -avx --delete  /$DIRECTORY/ /ovl/ro/$DIRECTORY/  >> /var/log/beforeend.log
		if [ $? -ne 0 ]; then
			$ECHO "ERROR: could not rsync /ovl/ro/$DIRECTORY " >> /var/log/beforeend.log
		else
			$ECHO "Done directory $DIRECTORY" >> /var/log/beforeend.log
		fi
	done
fi
$DATE>>/var/log/beforeend.log

