#!/bin/bash

# Read the file /proc/sys/kernel/kexec_load_disabled. If 1, then attempt to write 0 to it, if that write fails, then exit.
if [ "$(cat /proc/sys/kernel/kexec_load_disabled)" -eq 1 ]; then
    echo "Kexec disabled. Boot with 'kexec_load_disabled=0'"
    exit 1
fi

# Setup rootfs
sudo tar -xf /rootfs/rootfs.tar -C /rootfs
sudo cp -r /kernel/lib/* /rootfs/lib

cat << 'EOF' > /bin/distrousurp
#!/bin/bash
commandline=$(grep -o 'root=[^ ]*\|rd\.[^ ]*' /proc/cmdline | tr '\n' ' ')
commandline+="ro console=ttyS0,115200"
sudo /kernel/kexec -fd --initrd=/kernel/initramfs.cpio.zst --command-line="$commandline" /kernel/bzImage
EOF
chmod +x /bin/distrousurp


# Make this a ramfs overlay in the initramfs phase????
#sudo cp -r /kernel/lib/* /lib


#echo 0 | sudo tee /sys/class/vtconsole/vtcon1/bind



