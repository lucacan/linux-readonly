# linux-readonly
Some files to make the raspberry pi SD Read-only.
doRPIonPC.sh is executed by passing the device where to save the system (/dev/sda, /dev/sdb .. if adapters are used, /dev/mmcblk0 if connected directly to the PC).
Before launching the command, copy doRPI.sh file in the same folder.
The wired and/or wi-fi connections must be configured within the script.
ex:
doRPIonPC.sh / dev / mmcblk0

Then the produced SD must be disconnected, inserted in the PI and the PI connected to the power supply.
After a few tens of seconds you can log into the PI and run the script /root/doRPI.sh
At the end of the script to have the sd protected or unprotected run the commands /root/overlayOn.sh or overlayOff.sh
