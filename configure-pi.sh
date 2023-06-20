#!/bin/bash
# put in place by a clone of https://github.com/jantman/raspberry-pi-imager
# see /etc/image_version for repository path and version

if [ -z "$PI_HOSTNAME" ]; then
    read -sp "Hostname for new pi: " PI_HOSTNAME
fi

# password, if changing
# root ssh keys
# sudo apt install puppet git r10k
# echo -e "Host github.com\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n" >> ~/.ssh/config && chmod 0600 ~/.ssh/config
# sudo apt update && sudo apt upgrade && sudo reboot

# cd to the directory this script is in, even if it's a chroot
# the directory should always be the root/ directory relative to the filesystem
cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null

../usr/bin/raspi-config nonint do_hostname custom-pi-${var.sha}
