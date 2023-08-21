#!/bin/sh
/usr/bin/Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /var/log/Xorg.log -config /xorg.conf :1 &
while [ true ]
do
    /usr/local/UniVPN/UniVPN
    sleep 60
done