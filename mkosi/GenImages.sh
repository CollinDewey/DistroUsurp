#!/usr/bin/env bash

MNT_DIR=$(dirname "${BASH_SOURCE[0]}")

docker_cmd() {
    docker "$@"
}

build() {
    log_file="$MNT_DIR/out/build.log"
    docker_cmd run -it --privileged -v "$MNT_DIR:/mkosi" "$@" | tee -a "$log_file"
}

mkdir -p "$MNT_DIR/out"
rm -rf "$MNT_DIR/out/"*

# I really don't like this. But there doesn't seem to be a premade one distro that builds all.
build archlinux bash /mkosi/RunMkosi.sh ArchLinux
build kalilinux/kali-rolling bash /mkosi/RunMkosi.sh KaliLinux
build fedora:43 bash /mkosi/RunMkosi.sh Fedora43 Fedora42 RockyLinux9 AlmaLinux9
build ubuntu:25.04 bash /mkosi/RunMkosi.sh Ubuntu2504 Ubuntu2404 Debian12 Debian13

# Remove links
find "$MNT_DIR/out" -maxdepth 1 -type l -delete

# Generate distros.json
entries=()

for tar in "$MNT_DIR/out"/*.tar.zst; do
    name=$(basename "$tar" .tar.zst)
    entries+=("$(jq -n \
       --arg id "$name" \
       --arg name "$(<"$name/name.txt")" \
       --arg filename "$name.tar.zst" \
       --arg path "/" \
       --arg sha256 "$(sha256sum "$tar" | cut -d' ' -f1)" \
       --arg filesize "$(stat -c %s "$tar")" \
       '{id:$id, name:$name, filename:$filename, path:$path, sha256:$sha256, filesize:($filesize|tonumber)}')")
done

entries+=("$(jq -n \
    --arg id "archlinux-bootstrap" \
    --arg name "Arch Linux Bootstrap" \
    --arg filename "archlinux-bootstrap-2025.07.01-x86_64.tar.zst" \
    --arg path "https://mirrors.edge.kernel.org/archlinux/iso/2025.07.01/" \
    --arg sha256 "bc943f1d3d25d9350a23574b7eacdd8e00badd8f546ce05929d233b404bfd155" \
    --arg filesize "143253129" \
    '{id:$id, name:$name, filename:$filename, path:$path, sha256:$sha256, filesize:($filesize|tonumber)}')")

jq -n \
    --argjson version "1" \
    --argjson distros "$(printf '%s\n' "${entries[@]}" | jq -s .)" \
    '{version:$version, distros:$distros}' > "$MNT_DIR/out/distros.json"