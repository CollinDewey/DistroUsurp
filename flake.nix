{
  description = "DistroUsurp";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # Vagrant is non-free
      };
      kernel = pkgs.linuxPackages_latest;
      modules = pkgs.makeModulesClosure {
        rootModules = [
          # SATA/PATA/AHCI Controllers
          "ahci" "sata_nv" "sata_via" "sata_sis" "sata_uli" "ata_piix" "pata_marvell"
          
          # NVMe and Storage Devices
          "nvme" "sd_mod" "sr_mod" "mmc_block"
          
          # USB Host Controllers
          "uhci_hcd" "ehci_hcd" "ehci_pci" "ohci_hcd" "ohci_pci" "xhci_hcd" "xhci_pci"
          
          # USB Human Interface Devices (HID)
          "usbhid" "hid_generic" "hid_lenovo" "hid_apple" "hid_roccat" 
          "hid_logitech_hidpp" "hid_logitech_dj" "hid_microsoft" "hid_cherry" "hid_corsair"
          
          # USB Storage
          "usb_storage" "uas"
          
          # Volume Management and Device Mapper
          "vmd" "dm_mod" "dm_verity"
          
          # Virtualization (VirtIO)
          "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_net" "virtio_rng" 
          "virtio_balloon" "virtio_console"
          
          # Network Drivers
          "e1000" "af_packet"
          
          # Filesystem Support
          "autofs4" "squashfs" "overlay"
          
          # Common Filesystems
          "ext2" "ext3" "ext4" "btrfs" "xfs" "vfat" "fat" "ntfs3"
          
          # LVM and Advanced Device Mapper
          "dm-mirror" "dm-snapshot" "dm-raid" "linear"
        ]; # List from https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/system/boot/kernel.nix + USB storage
        allowMissing = true;
        kernel = kernel.kernel;
        firmware = [ pkgs.firmwareLinuxNonfree ];
      };
      mkinitcpio_conf = pkgs.writeText "mkinitcpio.conf" ''
        MODULES=(${pkgs.lib.concatStringsSep " " modules.rootModules}) # This should actually autodetect - TO TEST LATER
        BINARIES=( )
        FILES=( )
        #HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt block lvm2 filesystems fsck)
        HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)
      '';
    in
    {
      packages.${system} = {

        stage1 = pkgs.callPackage ./pkgs/stage1.nix {
          inherit modules kernel mkinitcpio_conf;
          mkinitcpio = self.packages.${system}.mkinitcpio;
        };

        mkinitcpio = pkgs.callPackage ./pkgs/mkinitcpio.nix { };

        default = self.packages.${system}.stage1;
      };
      
      devShells.${system}.default = pkgs.mkShell { buildInputs = with pkgs; [ vagrant shellcheck ]; };
    };
}