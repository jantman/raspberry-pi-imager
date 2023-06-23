#!/bin/bash
# put in place by a clone of https://github.com/jantman/raspberry-pi-imager
# see /etc/image_version for repository path and version

# exit early if someone is logged in on tty1
who | grep -q -E '\stty1\s' && exit 0

source /etc/image_version
HOST=$(hostname)

cat <<EOT > /dev/tty1

Hostname: ${HOST}
Image generated by ${IMAGE_REPO} @ ${IMAGE_SHA} (${IMAGE_RELEASE})
MAC ADDRESSES:
$(ip --brief link)
IP ADDRESSES:
$(ip --brief addr)
Date: $(date)
#####################################################################
EOT