{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "tools";
  version = "0.0.1";

  src = ./.;

  installPhase = ''
    cp ${pkgs.pkgsStatic.kexec-tools}/bin/kexec ./kexec
    cp ${pkgs.pkgsStatic.zstd}/bin/zstd ./zstd
    cp ${pkgs.pkgsStatic.su.out}/bin/useradd ./useradd
    cp ${pkgs.pkgsStatic.mkpasswd}/bin/mkpasswd ./mkpasswd
    chmod +x ./kexec ./zstd ./useradd ./mkpasswd
    tar -cf tools.tar \
      kexec \
      zstd \
      useradd \
      mkpasswd
    install -Dm644 tools.tar $out
  '';

  dontFixup = true;
}