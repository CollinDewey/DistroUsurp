# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  #config.vm.synced_folder "../dump", "/dump"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./result", "/kernel", type: "rsync"
  config.vm.synced_folder "./rootfs", "/rootfs", type: "rsync"
  config.vm.provision "shell", path: "./scripts/kexec.sh"


  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 4096
    libvirt.cpus = 4
  end

  # Ubuntu 22.04 LTS - systemd 249 (249.11-0ubuntu3.11)
  config.vm.define "ubuntu22" do |ubuntu22|
    ubuntu22.vm.box = "generic/ubuntu2204"
    ubuntu22.vm.hostname = "ubuntu22"
  end

  # Ubuntu 20.04 LTS - systemd 245 (245.4-4ubuntu3.22)
  config.vm.define "ubuntu20" do |ubuntu20|
    ubuntu20.vm.box = "generic/ubuntu2004"
    ubuntu20.vm.hostname = "ubuntu20"
  end

  # Ubuntu 18.04 LTS - systemd 237
  config.vm.define "ubuntu18" do |ubuntu18|
    ubuntu18.vm.box = "generic/ubuntu1804"
    ubuntu18.vm.hostname = "ubuntu18"
  end

  # Ubuntu 16.04 LTS - systemd 229
  config.vm.define "ubuntu16" do |ubuntu16|
    ubuntu16.vm.box = "generic/ubuntu1604"
    ubuntu16.vm.hostname = "ubuntu16"
  end

  # Debian 12 - systemd 252 (252.33-1~deb12u1)
  config.vm.define "debian12" do |debian12|
    debian12.vm.box = "debian/bookworm64"
    debian12.vm.hostname = "debian12"
  end

  # Debian 11 - systemd 247 (247.3-7+deb11u5)
  config.vm.define "debian11" do |debian11|
    debian11.vm.box = "debian/bullseye64"
    debian11.vm.hostname = "debian11"
  end

  # Debian 10 - systemd 241 (241)
  config.vm.define "debian10" do |debian10|
    debian10.vm.box = "debian/buster64"
    debian10.vm.hostname = "debian10"
  end

  # Debian 9 - systemd 232
  config.vm.define "debian9" do |debian9|
    debian9.vm.box = "debian/stretch64"
    debian9.vm.hostname = "debian9"
  end

  # Debian 8 - systemd 215 (But rsync refused)
  #config.vm.define "debian8" do |debian8|
  #  debian8.vm.box = "debian/jessie64"
  #  debian8.vm.hostname = "debian8"
  #end

  # openSUSE Leap 15.6 - systemd 254 (254.15+suse.93.g957aeb6452)
  config.vm.define "opensuse156" do |opensuse156|
    opensuse156.vm.box = "opensuse/Leap-15.6.x86_64"
    opensuse156.vm.hostname = "opensuse156"
  end

  # Rocky Linux 9 - systemd 252 (252-18.el9)
  config.vm.define "rocky9" do |rocky9|
    rocky9.vm.box = "generic/rocky9"
    rocky9.vm.hostname = "rocky9"
  end

  # Rocky Linux 8 - systemd 239 (239-78.el8)
  config.vm.define "rocky8" do |rocky8|
    rocky8.vm.box = "generic/rocky8"
    rocky8.vm.hostname = "rocky8"
  end

  # AlmaLinux 9 - systemd 252 (252-51.el9.alma.1)
  config.vm.define "almalinux9" do |almalinux9|
    almalinux9.vm.box = "almalinux/9"
    almalinux9.vm.hostname = "almalinux9"
  end

  # AlmaLinux 8 - systemd 239 (239-82.el8_10.3)
  config.vm.define "almalinux8" do |almalinux8|
    almalinux8.vm.box = "almalinux/8"
    almalinux8.vm.hostname = "almalinux8"
  end

  # Fedora 21 - systemd 216 (But rsync refused)
  #config.vm.define "fedora21" do |fedora21|
  #  fedora21.vm.box = "jimmidyson/fedora21-atomic"
  #  fedora21.vm.hostname = "fedora21"
  #end

  # CentOS 7 - systemd 219
  config.vm.define "centos7" do |centos7|
    centos7.vm.box = "generic/centos7"
    centos7.vm.hostname = "centos7"
  end

  # Now for the weird ones (aka non-SystemD)

  # CentOS 6 - upstart 0.6.5 (But rsync refused)
  #config.vm.define "centos6" do |centos6|
  #  centos6.vm.box = "generic/centos6"
  #  centos6.vm.hostname = "centos6"
  #end

  # Alpine Linux 3.21 - openrc (OpenRC 0.55.1)
  config.vm.define "alpine321" do |alpine321|
    alpine321.vm.box = "boxen/alpine-3.21"
    alpine321.vm.hostname = "alpine321"
  end

  # Devuan 5 - init
  config.vm.define "devuan5" do |devuan5|
    devuan5.vm.box = "generic/devuan5"
    devuan5.vm.hostname = "devuan5"
  end

end