#!/bin/bash

# Read the file /proc/sys/kernel/kexec_load_disabled. If 1, then attempt to write 0 to it, if that write fails, then exit.
if [ "$(cat /proc/sys/kernel/kexec_load_disabled)" -eq 1 ]; then
    echo "Kexec disabled. Boot with 'kexec_load_disabled=0'"
    exit 1
fi

# This installs kexec-tools across various distributions, but if we just compile kexec-tools ourselves, we can just include a static executable.
# The static executable is 371k, which is big but manageable.

#if command -v apt-get >/dev/null 2>&1; then # Debian
#    sudo DEBIAN_FRONTEND=noninteractive apt-get update
#    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y kexec-tools
#elif command -v yum >/dev/null 2>&1; then # Old RHEL
#    sudo yum install -y kexec-tools
#elif command -v dnf >/dev/null 2>&1; then # New RHEL
#    sudo dnf install -y kexec-tools
#elif command -v zypper >/dev/null 2>&1; then # SUSE
#    sudo zypper install -y kexec-tools
#elif command -v apk >/dev/null 2>&1; then # Alpine
#    sudo apk add kexec-tools
#else
#    echo "Package manager not found. Please install kexec-tools."
#    exit 1
#fi

cat /proc/cmdline

#commandline=$(cat /proc/cmdline)
commandline+="root=UUID=2705738d-1af1-4254-8aa0-ab59b4bdfb5e ro console=ttyS0,115200"

echo "Loading kexec"
sudo /kernel/kexec -fd --initrd=/kernel/initramfs.cpio.zst --command-line="$commandline" /kernel/bzImage

#
#if command -v systemctl >/dev/null 2>&1; then
#    sudo systemctl kexec
#else
#    echo "Systemd not found. Using kexec directly."
#    
#fi