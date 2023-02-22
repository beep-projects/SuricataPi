#!/bin/bash

#######################################
# print an error message and exit with given code.
# Globals:
#   None
# Arguments:
#   $1 the error message to print
#   $2 optional exit code
# Outputs:
#   Prints error message to stdout
#   returns with exit code if given
#######################################
function error {
    printf "%s\n" "${1}" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

FILES_FOR_PI_FOLDER="scripts"

mkdir -p temp
cd temp || error "temp was not created"
#make sure there is no old stuff present
if [[ -d "SuricataPi" ]]; then
  rm -rf "SuricataPi"
fi

git clone https://github.com/beep-projects/SuricataPi
cd SuricataPi || error "git clone failed"

read -rp "Enter hostname for your pi: " HOSTNAME
read -rp "Enter username for the default user on your pi: " USERNAME
read -rp "Enter password for the default user on your pi: " PASSWORD
read -rp "Enter the SSID of your WiFi: " SSID

sed -i "s/^HOSTNAME=.*/HOSTNAME=${HOSTNAME}/" ${FILES_FOR_PI_FOLDER}/firstrun.sh
sed -i "s/^USERNAME=.*/USERNAME=${USERNAME}/" ${FILES_FOR_PI_FOLDER}/firstrun.sh
mkpasswd "${PASSWORD}" --method=SHA-256 -S "beepprojects" | (read -r PWD && PWD=$(printf '%s\n' "$PWD" | sed 's/[[\.*^$/]/\\&/g') && sed -i "s/^PASSWD=.*/PASSWD='${PWD}'/" ${FILES_FOR_PI_FOLDER}/firstrun.sh)
sed -i "s/^SSID=.*/SSID=${SSID}/" ${FILES_FOR_PI_FOLDER}/firstrun.sh
wpa_passphrase "${SSID}" | grep "\spsk" | cut -d '=' -f 2 | (read -r PWD && PWD=$(printf '%s\n' "$PWD" | sed 's/[[\.*^$/]/\\&/g') && sed -i "s/^WPA_PASSPHRASE=.*/WPA_PASSPHRASE=${PWD}/" ${FILES_FOR_PI_FOLDER}/firstrun.sh)

read -erp "Enter HOME_NET to be used by Suricata, separating CIDR blocks with comma (,): " -i "192.168.0.0/16,172.16.0.0/12,10.0.0.0/8" HOME_NET
HOME_NET="[${HOME_NET}]"
sed -i "s|^HOME_NET=.*|HOME_NET=${HOME_NET}|" ${FILES_FOR_PI_FOLDER}/firstrun.sh

USE_LATEST_RASPI_OS=false
while true; do
    read -rp "Do you want to use latset Raspberry Pi OS (y, Y, yes) or use the last tetsted one (n, N, no)?" yn
    case $yn in
        y | Y | yes | Yes ) USE_LATEST_RASPI_OS=true; break;;
        n | N | no | No ) ;;
        * ) echo "Please answer yes or no.";;
    esac
done
sed -i "s/^USE_LATEST_RASPI_OS=.*/USE_LATEST_RASPI_OS=${USE_LATEST_RASPI_OS}/" ./install_suricatapi.sh

./install_suricatapi.sh