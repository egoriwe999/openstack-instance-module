#!/bin/bash

DEVICE=${1?'Device is not specified!'}
MOUNT_PATH=${2?'Mount path is not specified!'}

[ $(id -u) != 0 ] && echo "$0: must run as root!" && exit 1

CreateAndFormat() {
    # create partition, format as ext4
    sgdisk -N 1 "${DEVICE}" && mkfs.ext4 "${DEVICE}1"
}

RegisterMount() {
    # check if the partition is already registered before updating /etc/fstab
    grep -q "${DEVICE}1 ${MOUNT_PATH}" /etc/fstab || \
        echo "${DEVICE}1 ${MOUNT_PATH} ext4 rw,errors=remount-ro 0 0" | tee -a /etc/fstab
}

mkdir -p "${MOUNT_PATH}"
RegisterMount

# if there's an existing partition, resize the file system
if blkid | grep -wq "${DEVICE}1"; then
    umount "${MOUNT_PATH}"
    # move the last sector
    sgdisk -e "${DEVICE}"
    # get existing partition ID so we can resize it
    GUID=$(sgdisk -i 1 "${DEVICE}"|grep 'unique GUID'|awk '{print $4}')
    # extend the partition
    sgdisk -d 1 -n 1:0:0 -u "1:${GUID}" "${DEVICE}"
    # resize the file system
    e2fsck -fy "${DEVICE}1"
    resize2fs "${DEVICE}1"
else
    # otherwise, create a partition and format it
    CreateAndFormat
fi

mount -a