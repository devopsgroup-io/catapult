#!/usr/bin/env bash

kernel_running=$(uname --release)
kernel_running="kernel-${kernel_running}"
kernel_staged=$(rpm --last --query kernel | head --lines 1 | awk '{print $1}')
if [ "${kernel_running}" != "${kernel_staged}" ]; then
    reboot
fi
