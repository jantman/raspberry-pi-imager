#!/bin/bash

DEST=/etc/issue.d/rpi-image.issue
source /etc/image_version
HOST=$(hostname)

echo "Image generated by ${IMAGE_REPO} @ ${IMAGE_SHA} (${IMAGE_RELEASE})" > $DEST
echo "Hostname: ${HOST}" >> $DEST
echo "MAC ADDRESSES:" >> $DEST
ip --brief link >> $DEST
echo "IP ADDRESSES:" >> $DEST
ip --brief addr >> $DEST
echo "Date: $(date)" >> $DEST
