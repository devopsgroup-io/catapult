#!/bin/bash

kernel_running=$(/bin/uname --release)
kernel_running="kernel-${kernel_running}"
kernel_staged=$(/bin/rpm --last --query kernel | /bin/head --lines 1 | /bin/awk '{print $1}')
if [ "${kernel_running}" != "${kernel_staged}" ]; then
    /sbin/reboot
fi
