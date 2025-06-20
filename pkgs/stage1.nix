{ pkgs, modules, kernel, mkinitcpio, mkinitcpio_conf }:

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

    mkinitcpio --kernel ${kernel.kernel.version} --moduleroot $kernel_libs --config ${mkinitcpio_conf} --generate initramfs.cpio.zst --nocolor
  '';

  installPhase = ''
    mkdir -p $out
    cp -r $kernel_libs/* $out
    cp initramfs.cpio.zst $out
    cp ${pkgs.pkgsStatic.kexec-tools}/bin/kexec $out
    cp ${kernel.kernel}/bzImage $out
  '';

  dontFixup = true;
}