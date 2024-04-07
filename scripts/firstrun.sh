#!/bin/bash
#
# Copyright (c) 2022-2024, The beep-projects contributors
# this file originated from https://github.com/beep-projects
# Do not remove the lines above.
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see https://www.gnu.org/licenses/
#
# This file is inspired by the firstrun.sh, generated by the Raspberry Pi Imager https://www.raspberrypi.org/software/
#
# This file will setup a raspberrypi with wifi, timezone and keyboard configured
# and sets up the secondrun.service to be started after the next boot.
# At the second boot, networking should be configured
# so that the system can be updated and new software can be downloaded and installed
# For a full description see https://github.com/beep-projects/SuricataPi/readme.md
#
# This script is run as root, no need for sudo

# redirect output to 'firstrun.log':
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/boot/firstrun.log 2>&1

echo "START firstrun.sh"
echo "This script is running as user: $( whoami )"

#-------------------------------------------------------------------------------
#----------------------- START OF CONFIGURATION --------------------------------
#-------------------------------------------------------------------------------

# use the last tested ELK stack, or the newest one
USE_LATEST_ELK=false
# home net for suricata configuration, defaults to all private IPv4s
HOME_NET="[192.168.0.0/16,172.16.0.0/12,10.0.0.0/8]" 
# which hostname do you want to give your raspberry pi?
HOSTNAME=suricatapi
# username: beep, password: projects
# you can change the password if you want and generate a new password with
# Linux: mkpasswd --method=SHA-256
# Windows: you can use an online generator like https://www.dcode.fr/crypt-hasing-function
USERNAME=beep
# shellcheck disable=SC2016
PASSWD='$5$oLShbrSnGq$nrbeFyt99o2jOsBe1XRNqev5sWccQw8Uvyt8jK9mFR9' #keep single quote to avoid expansion of $
# configure the wifi connection
# the example WPA_PASSPHRASE is generated via
#     wpa_passphrase MY_WIFI passphrase
# but you also can enter your passphrase as plain text, if you accept the potential insecurity of that approach
SSID=MY_WIFI
WPA_PASSPHRASE=3755b1112a687d1d37973547f94d218e6673f99f73346967a6a11f4ce386e41e
# set your locale, get all available: cat /usr/share/i18n/SUPPORTED
LOCALE="de_DE.UTF-8"
# configure your timezone and key board settings
TIMEZONE="Europe/Berlin"
COUNTRY="DE"
XKBMODEL="pc105"
XKBLAYOUT=$COUNTRY
XKBVARIANT=""
XKBOPTIONS=""

#-------------------------------------------------------------------------------
#------------------------ END OF CONFIGURATION ---------------------------------
#-------------------------------------------------------------------------------
# configure your locale
sudo locale-gen "$LOCALE"
sudo update-locale LANG="$LOCALE"

# Prior to Bookworm, Raspberry Pi OS stored the boot partition at /boot/.
# Since Bookworm, the boot partition is located at /boot/firmware/. 
echo "checking if files were moved to /boot/firmware"
if [ -f /boot/firmware/secondrun.sh ]; then
   echo "ln -s /boot/firmware/secondrun.sh /boot/secondrun.sh"
   ln -s /boot/firmware/secondrun.sh /boot/secondrun.sh
fi
if [ -f /boot/firmware/thirdrun.sh ]; then
   echo "ln -s /boot/firmware/thirdrun.sh /boot/thirdrun.sh"
   ln -s /boot/firmware/thirdrun.sh /boot/thirdrun.sh
fi
if [ -f /boot/firmware/10-suricata.conf ]; then
   echo "ln -s /boot/firmware/10-suricata.conf /boot/10-suricata.conf"
   ln -s /boot/firmware/10-suricata.conf /boot/10-suricata.conf
fi
if [ -f /boot/firmware/SuricataPi.ndjson ]; then
   echo "ln -s /boot/firmware/SuricataPi.ndjson /boot/SuricataPi.ndjson"
   ln -s /boot/firmware/SuricataPi.ndjson /boot/SuricataPi.ndjson
fi
if [ -f /boot/firmware/suricatapi-index-policy.json ]; then
   echo "ln -s /boot/firmware/suricatapi-index-policy.json /boot/suricatapi-index-policy.json"
   ln -s /boot/firmware/suricatapi-index-policy.json /boot/suricatapi-index-policy.json
fi
if [ -f /boot/firmware/suricatapi-index-template.json ]; then
   echo "ln -s /boot/firmware/suricatapi-index-template.json /boot/suricatapi-index-template.json"
   ln -s /boot/firmware/suricatapi-index-template.json /boot/suricatapi-index-template.json
fi

# latest tested ELK stack version
ELK_REPO_VERSION=8

#copy the USE_LATEST_ELK into secondrun.sh 
sed -i "s/^USE_LATEST_ELK=.*/USE_LATEST_ELK=${USE_LATEST_ELK}/" /boot/secondrun.sh
sed -i "s/^ELK_REPO_VERSION=.*/ELK_REPO_VERSION=${ELK_REPO_VERSION}/" /boot/secondrun.sh
#copy the USERNAME into secondrun.sh 
sed -i "s/^USERNAME=.*/USERNAME=${USERNAME}/" /boot/secondrun.sh
#copy the HOME_NET into secondrun.sh 
sed -i "s|^HOME_NET=.*|HOME_NET=${HOME_NET}|" /boot/secondrun.sh

# set hostname and username
CURRENT_HOSTNAME=$( </etc/hostname tr -d " \t\n\r" )
echo "set hostname to ${HOSTNAME} (was ${CURRENT_HOSTNAME})"
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_hostname ${HOSTNAME}
else
   echo ${HOSTNAME} >/etc/hostname
   sed -i "s/127.0.1.1.*${CURRENT_HOSTNAME}/127.0.1.1\t${HOSTNAME}/g" /etc/hosts
fi

FIRSTUSER=$( getent passwd 1000 | cut -d: -f1 )
echo "set default user to ${USERNAME} (was ${FIRSTUSER})"
#FIRSTUSERHOME=$( getent passwd 1000 | cut -d: -f6 )
if [ -f /usr/lib/userconf-pi/userconf ]; then
   echo "/usr/lib/userconf-pi/userconf \"${USERNAME}\" \"${PASSWD}\""
   /usr/lib/userconf-pi/userconf "${USERNAME}" "${PASSWD}"
else
   echo "echo ${FIRSTUSER}:${PASSWD} | chpasswd -e"
   echo "${FIRSTUSER}:${PASSWD}" | chpasswd -e
   if [ "${FIRSTUSER}" != "${USERNAME}" ]; then
      echo "user name has changed to: ${USERNAME}"
      usermod -l "${USERNAME}" "${FIRSTUSER}"
      usermod -m -d "/home/${USERNAME}" "${USERNAME}"
      groupmod -n "${USERNAME}" "${FIRSTUSER}"
      if grep -q "^autologin-user=" /etc/lightdm/lightdm.conf ; then
         sed /etc/lightdm/lightdm.conf -i -e "s/^autologin-user=.*/autologin-user=${USERNAME}/"
      fi
      if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
         sed /etc/systemd/system/getty@tty1.service.d/autologin.conf -i -e "s/${FIRSTUSER}/${USERNAME}/"
      fi
      if [ -f /etc/sudoers.d/010_pi-nopasswd ]; then
         sed -i "s/^${FIRSTUSER} /${USERNAME} /" /etc/sudoers.d/010_pi-nopasswd
      fi
   fi
fi

echo "setting network options"
#sed -i "s/^REGDOMAIN=.*/REGDOMAIN=${COUNTRY}/" /etc/default/crda

if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom enable_ssh
else
   systemctl enable ssh
fi

if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_wlan "${SSID}" "${WPA_PASSPHRASE}" "${COUNTRY}"
else
cat >/etc/wpa_supplicant/wpa_supplicant.conf <<WPAEOF
country=$COUNTRY
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
ap_scan=1

update_config=1
network={
	ssid="$SSID"
	psk=$WPA_PASSPHRASE
}

WPAEOF
   chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
   rfkill unblock wifi
   for filename in /var/lib/systemd/rfkill/*:wlan ; do
     echo 0 > "${filename}"
   done
fi

#Disable "Welcome to Raspberry Pi" setup wizard at system start
if [ -f /etc/xdg/autostart/piwiz.desktop ]; then
   rm -f /etc/xdg/autostart/piwiz.desktop
fi

if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_keymap "${COUNTRY}"
   /usr/lib/raspberrypi-sys-mods/imager_custom set_timezone "${TIMEZONE}"
else
   rm -f /etc/localtime
   echo "${TIMEZONE}" >/etc/timezone
   dpkg-reconfigure -f noninteractive tzdata
cat >/etc/default/keyboard <<KBEOF
XKBMODEL=$XKBMODEL
XKBLAYOUT=$XKBLAYOUT
XKBVARIANT=$XKBVARIANT
XKBOPTIONS=$XKBOPTIONS
KBEOF
   dpkg-reconfigure -f noninteractive keyboard-configuration
fi

echo "installing secondrun.service"
# make sure secondrun.sh is executed at next boot. 
# we will need network up and running, so we install the script as a service that depends on network
echo "create /etc/systemd/system/secondrun.service"
cat <<EOF | sudo tee /etc/systemd/system/secondrun.service
[Unit]
Description=SecondRun
After=network.target
Before=rc-local.service
ConditionFileNotEmpty=/boot/secondrun.sh

[Service]
WorkingDirectory=/boot
ExecStart=/boot/secondrun.sh
Type=oneshot
RemainAfterExit=no

[Install]
WantedBy=multi-user.target

EOF
echo "enable secondrun.service"
#reload systemd to make the daemon aware of the new configuration
systemctl --system daemon-reload
#enable service
systemctl enable secondrun.service

#clean up
echo "removing firstrun.sh from /boot/cmdline.txt"
#rm -f /boot/firstrun.sh
sed -i "s| systemd.run.*||g" /boot/cmdline.txt

echo "DONE firstrun.sh"

exit 0
