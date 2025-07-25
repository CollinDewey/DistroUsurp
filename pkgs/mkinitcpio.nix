{ lib, pkgs, mkinitcpio-unwrapped }:

let
  runtimePackages = with pkgs; [
    systemd
    gawk
    kmod
    util-linux
    libarchive
    coreutils
    bash
    binutils
    diffutils
    findutils
    gnugrep
    gnused
    gzip
    zstd
    mkinitcpio-nfs-utils
    kbd # setfont
    e2fsprogs # fsck
    btrfs-progs # fsck 
    libxfs # fsck
    getent
    openssl # SystemD-based initramfs
    thin-provisioning-tools # pdata_tools
    lvm2
  ];

in pkgs.buildFHSEnv {
  name = "mkinitcpio";
  
  targetPkgs = pkgs: runtimePackages ++ [ mkinitcpio-unwrapped ];

  runScript = "mkinitcpio";

  meta = with lib; {
    homepage = "https://archlinux.org/";
    description = "Modular initramfs image creation utility";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}