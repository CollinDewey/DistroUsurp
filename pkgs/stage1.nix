{ pkgs, modules, kernel, mkinitcpio, mkinitcpio-unwrapped, mkinitcpio_conf }:

let
  distrousurp-hook = pkgs.writeText "distrousurp-hook" ''
    #!/usr/bin/ash

    run_latehook() {
        if [ -f /new_root/distrousurp/rootfs/sbin/init ]; then
            msg ':: Moving root...'
            mkdir -p /tmp/original_root
            mount --move /new_root /tmp/original_root
    
            msg ':: Bind mounting new root...'
            mkdir -p /new_root
            mount --bind /tmp/original_root/distrousurp/rootfs /new_root

            msg ':: Moving old root to within new root...'
            mkdir -p /new_root/old_root
            mount --move /tmp/original_root /new_root/old_root
    
            # Prevent infinite loop
            msg ':: Masking rootfs dir within new root...'
            mkdir -p /new_root/old_root/distrousurp/rootfs
            mount -t tmpfs none /new_root/old_root/distrousurp/rootfs
            mount -o remount,ro,bind /new_root/old_root/distrousurp/rootfs
        fi

        if [ ! -d /new_root/lib/modules/${kernel.kernel.version}/kernel ]; then
            # Copy kernel modules
            msg ':: Copying kernel modules...'
            mkdir -p /new_root/lib/modules/${kernel.kernel.version}/kernel
            cp -r /lib/modules/${kernel.kernel.version}/kernel/* /new_root/lib/modules/${kernel.kernel.version}/kernel/
        fi

    }
  '';

  distrousurp-install = pkgs.writeText "distrousurp-install" ''
    #!/usr/bin/env bash

    build() {
        add_runscript
    }

    help() {
        cat <<HELPEOF
    Distrousurp hook. Mounts a new root at /distrousurp/rootfs
    HELPEOF
    }
  '';

in
pkgs.stdenv.mkDerivation {
  pname = "stage1";
  version = "0.0.1";

  src = ./.;

  nativeBuildInputs = [
    mkinitcpio
    modules
  ];
  
  buildPhase = ''
    kernel_libs=$(mktemp -d)
    mkdir -p $kernel_libs/lib
    cp -r --no-preserve=mode ${modules}/lib/* $kernel_libs/lib
    cp -r --no-preserve=mode ${kernel.kernel}/lib/* $kernel_libs/lib

    hooks=$(mktemp -d)
    cp -r --no-preserve=mode ${mkinitcpio-unwrapped}/lib/initcpio/* $hooks/
    cp --no-preserve=mode ${distrousurp-install} $hooks/install/distrousurp
    cp --no-preserve=mode ${distrousurp-hook} $hooks/hooks/distrousurp
    
    mkinitcpio --kernel ${kernel.kernel.version} --moduleroot $kernel_libs --config ${mkinitcpio_conf} --generate initramfs.cpio.zst --hookdir $hooks --nocolor
  '';

  installPhase = ''
    cp ${kernel.kernel}/bzImage ./bzImage
    tar -cf ${kernel.kernel.version}.tar \
      initramfs.cpio.zst \
      bzImage
    install -Dm644 ${kernel.kernel.version}.tar $out
  '';

  dontFixup = true;
}