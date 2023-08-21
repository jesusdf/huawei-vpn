#!/bin/sh
echo "tmpfs	/tmp	tmpfs	rw	0	0" >> /etc/fstab
mount /tmp
/usr/bin/Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/Xorg.log -config /xorg.conf :1 &
while [ true ]
do
    /usr/local/UniVPN/UniVPN
    sleep 60
done