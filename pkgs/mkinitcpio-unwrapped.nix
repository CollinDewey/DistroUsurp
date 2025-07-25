{ lib, stdenv, pkgs }:

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
in
stdenv.mkDerivation {
  pname = "mkinitcpio";
  version = "a6ef10d3";

  src = pkgs.fetchFromGitLab {
    owner = "archlinux";
    repo = "mkinitcpio/mkinitcpio";
    rev = "a6ef10d3f4f24029fc649686ba36f692d8575a7a";
    hash = "sha256-Tsg3DUOBHa4O4n33V5Ty7inXwcgWwhy4zTXgHOhchfY=";
    domain = "gitlab.archlinux.org";
    leaveDotGit = true; # This is bad and WILL break (nixpkgs#8567)
  };

  nativeBuildInputs = with pkgs; [ 
    asciidoctor
    asciidoc
    git
    meson
    ninja
    pkg-config
    shellcheck
    bats
    kcov
    systemd
    makeWrapper
  ];

  buildInputs = runtimePackages;

  patches = [
    ./udev.patch
    ./module_location_fix.patch
  ];

  postPatch = ''
    # The installer wants to place stuff in systemd's folders
    substituteInPlace meson.build \
      --replace-fail "systemd.get_variable('systemd_system_unit_dir')" "'$out/lib/systemd/system'" \
      --replace-fail "systemd.get_variable('tmpfiles_dir')" "'$out/lib/systemd/tmpfiles.d'"

    substituteInPlace install/sd-vconsole \
      --replace-fail "/usr/share/kbd/keymaps" "/usr/share/keymaps"

    # This runs at build time, and uses /bin/bash
    patchShebangs tools/dist.sh
  '';

  # /etc by default
  mesonFlags = [ "-Dsysconfdir=etc" ];

  postInstall = ''
    mkdir -p $out/lib/initcpio $out/lib/tmpfiles.d $out/lib/systemd/system
    ln -s ${pkgs.pkgsStatic.busybox}/bin/busybox $out/lib/initcpio/busybox
    ln -s ${pkgs.systemd}/share/factory/etc/vconsole.conf $out/etc/vconsole.conf

    # Copy SystemD example config files
    cp -r ${pkgs.systemd}/example/systemd/system/* $out/lib/systemd/system/
    ln -s ${pkgs.systemd}/example/tmpfiles.d/systemd.conf $out/lib/tmpfiles.d/systemd.conf
    ln -s ${pkgs.systemd}/example/tmpfiles.d/20-systemd-stub.conf $out/lib/tmpfiles.d/20-systemd-stub.conf
  '';

  meta = with lib; {
    homepage = "https://archlinux.org/";
    description = "Modular initramfs image creation utility";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}