#!/bin/bash
# put in place by a clone of https://github.com/jantman/raspberry-pi-imager
# see /etc/image_version for repository path and version

# cd to the directory this script is in, even if it's a chroot
# the directory should always be the root/ directory relative to the filesystem
cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null

# set hostname
if [ -z "$PI_HOSTNAME" ]; then
    read -p "Hostname for new pi: " PI_HOSTNAME
fi
../usr/bin/raspi-config nonint do_hostname ${PI_HOSTNAME}
echo "Hostname updated to: ${PI_HOSTNAME}"

# change pi password
read -p "Change password for default user? [y|N]" dochange
[[ "$dochange" == "y" ]] && passwd pi

# root ssh keys
if [ ! -e ./.ssh ]; then
    install -d -m 0700 -o root -g root .ssh
    echo "Created directory root/.ssh"
fi

ssh-keygen -b 2048 -f ./.ssh/id_rsa -N '' -t rsa
echo "Root public SSH key:"
cat ./.ssh/id_rsa.pub

read -p "Run apt update && apt upgrade && reboot now? [y|N]" doupdate
if [[ "$doupdate" == "y" ]]; then
	echo "Running: apt update && apt upgrade && reboot"
	apt update && apt upgrade && reboot
else
	echo -e "\n\nOnce up and running, please: sudo apt update && sudo apt upgrade && sudo reboot"
fi
