#!/bin/sh

# /tmp on tmpfs
echo "tmpfs	/tmp	tmpfs	rw	0	0" >> /etc/fstab
mkdir /tmp
mount /tmp

# Dummy X11
/usr/bin/Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/Xorg.log -config /xorg.conf :1 &

# Loop application
while [ true ]
do
    /usr/local/UniVPN/UniVPN
    sleep 60
done