# DistroUsurp

> Not ready for usage.

Tool used to replace an existing distro on a machine.

To build the distrousurp tool, run ./perl/build.sh
To build distributions, run ./mkosi/GenImages.sh
To build the kernel, run nix build .#stage1
To build statically compiled tools, run nix build .#tools