#!/bin/sh

export DISPLAY=:1

# /tmp on tmpfs
echo "tmpfs	/tmp	tmpfs	rw	0	0" >> /etc/fstab
mkdir /tmp
mount /tmp

# Dummy X11
/usr/bin/systemctl disable systemd-logind
/usr/bin/systemctl stop systemd-logind
/etc/init.d/dbus start
/usr/bin/Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/Xorg.log -config /xorg.conf :1 &
( sleep 5 && /usr/bin/xhost + && /usr/bin/x11vnc -safer -nopw -display :1 ) &

# Loop application
while [ true ]
do
    /usr/local/UniVPN/UniVPN
    sleep 60
done