#!/usr/bin/env bash

if command -v pacman &> /dev/null; then
    pacman -Sy --needed --noconfirm mkosi
elif command -v dnf &> /dev/null; then
    dnf install -y mkosi systemd-repart
elif command -v apt-get &> /dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y mkosi
fi

cd /mkosi || exit
for distro in "$@"; do
    mkosi --directory="./$distro" build
done