#!/usr/bin/env perl

use strict;
use warnings;
use JSON;
use File::Path qw(make_path remove_tree);
use Digest::SHA qw(sha256_hex);
use File::Spec;

my $BASE_DIR     = '/distrousurp';
my $DISTROS_JSON = "$BASE_DIR/distros.json";
my $ROOTFS_DIR   = "$BASE_DIR/rootfs";
my $BASE_URL     = 'https://teal.terascripting.com/public/distrousurp';
my $JSON_VERSION = 1;

sub must_be_root {
    my ($cmd) = @_;
    unless ($< == 0) {
        print STDERR "Error: '$cmd' must be run as root or with elevated privileges.\n";
        exit 1;
    }
}

# Perl has a few libraries for downloading stuff from the internet but I couldn't get SSL to compile on cosmo
sub download_file {
    my ($url, $output_file) = @_;
    
    my $has_wget = system("command -v wget >/dev/null 2>&1") == 0;
    my $has_curl = system("command -v curl >/dev/null 2>&1") == 0;
    
    if (!$has_wget && !$has_curl) {
        print STDERR "Error: Neither wget nor curl is available. Please install one of them.\n";
        exit 1;
    }
    
    my $cmd = $has_wget 
        ? "wget --no-check-certificate -q -O \"$output_file\" \"$url\""
        : "curl -s -k -L -o \"$output_file\" \"$url\"";
    
    system($cmd) == 0 or do {
        print STDERR "Error: Failed to download $url\n";
        exit 1;
    };
    
    return { success => 1 };
}

sub get_url_content {
    my ($url) = @_;
    
    make_path($BASE_DIR) unless -d $BASE_DIR;
    my $temp_file = "$BASE_DIR/temp_" . time() . "_" . int(rand(1000));
    
    download_file($url, $temp_file);
    
    open my $fh, '<', $temp_file or do {
        print STDERR "Error: Cannot open temporary file: $!\n";
        unlink $temp_file;
        exit 1;
    };
    
    my $content = do { local $/; <$fh> };
    close $fh;
    unlink $temp_file;
    
    return { success => 1, content => $content };
}

sub download_stage1 {
    # If we're downloading these, we should already have sudo
    my @names = ("tools", "kernel");

    for my $name (@names) {
        print "Downloading $name...\n";
        my $url = "$BASE_URL/$name.tar";
        my $response = download_file($url, "$BASE_DIR/$name.tar", 1);
        
        make_path("$BASE_DIR/$name");
        my $cmd = "tar -xf \"$BASE_DIR/$name.tar\" -C \"$BASE_DIR/$name\"";
        system($cmd) == 0 or die "Failed to extract $name\n";
        unlink "$BASE_DIR/$name.tar";
    }
}

sub update {
    must_be_root("update");
    print "Updating distribution list...\n";

    make_path($BASE_DIR) unless -d $BASE_DIR;
    
    my $response = get_url_content("$BASE_URL/distros.json");
    
    if ($response->{success}) {
        my $json_data = $response->{content};
        my $data;
        eval {
            $data = decode_json($json_data);
        };
        if ($@) {
            die "Invalid JSON.\n";
        }
        if (!exists $data->{version} || $data->{version} != $JSON_VERSION) {
            print STDERR "Error: JSON version ($data->{version}) does not match expected version ($JSON_VERSION).\n";
            return;
        }
        open my $fh, '>', $DISTROS_JSON or die "Cannot open $DISTROS_JSON for writing: $!";
        print $fh $json_data;
        close $fh;
        print "Successfully updated distribution list\n";
    } else {
        die "Failed to download distribution list: $response->{status} $response->{reason}";
    }
}

sub format_filesize {
    my ($size) = @_;
    my @units = ('B', 'K', 'M', 'G', 'T');
    my $i = 0;
    while ($size >= 1024 && $i < $#units) {
        $size /= 1024;
        $i++;
    }
    return sprintf("%.0f%s", $size, $units[$i]);
}

sub list {
    update() unless -f $DISTROS_JSON;
    
    open my $fh, '<', $DISTROS_JSON or die "Cannot open $DISTROS_JSON for reading: $!";
    my $json_data = do { local $/; <$fh> };
    close $fh;
    
    my $data = decode_json($json_data);
    foreach my $distro (@{$data->{distros}}) {
        my $readable_size = format_filesize($distro->{filesize});
        printf "%s (%s) (%s)\n", $distro->{name}, $distro->{id}, $readable_size;
    }
}

sub fetch {
    must_be_root("fetch");
    my ($id) = @_;
    die "Usage: distrousurp fetch <ID>\n" unless defined $id;
    
    if (-d $ROOTFS_DIR) {
        die "Rootfs directory already exists. Run 'distrousurp clean' first.\n";
    }
    update() unless -f $DISTROS_JSON;
    unless (-d "$BASE_DIR/tools" && -d "$BASE_DIR/kernel") {
        download_stage1();
    }
    open my $fh, '<', $DISTROS_JSON or die "Cannot open $DISTROS_JSON for reading: $!";
    my $json_data = do { local $/; <$fh> };
    close $fh;
    my $data = decode_json($json_data);
    my ($distro) = grep { $_->{id} eq $id } @{$data->{distros}};
    die "Distribution with ID '$id' not found.\n" unless $distro;
    my $url;
    if ($distro->{path} =~ m{^https?://}) {
        $url = $distro->{path} . $distro->{filename};
    } else {
        $url = $BASE_URL . $distro->{path} . $distro->{filename};
    }
    my $download_path = File::Spec->catfile($BASE_DIR, $distro->{filename});
    print "Downloading $distro->{name} from $url...\n";
    my $response = download_file($url, $download_path, 1);
    
    print "Verifying checksum...\n";
    open $fh, '<:raw', $download_path or die "Cannot open downloaded file: $!";
    my $sha256 = sha256_hex(do { local $/; <$fh> });
    close $fh;
    if ($sha256 ne $distro->{sha256}) {
        unlink $download_path;
        die "Checksum verification failed. Run 'distrousurp update'? Expected: $distro->{sha256}, Got: $sha256\n";
    }
    print "Extracting...\n";
    make_path($ROOTFS_DIR);
    # I should check to make sure zstd exists, as well as tar
    # zstd is fairly new, so that's why I'm bringing in a static binary, for Ubuntu 16.04
    my $cmd = "$BASE_DIR/tools/zstd -d \"$download_path\" --stdout | tar --warning=no-timestamp -x -C \"$ROOTFS_DIR\"";
    system($cmd);
    if ($? != 0) {
        remove_tree($ROOTFS_DIR);
        die "Extraction failed with exit code " . ($? >> 8) . "\n";
    }
    unlink $download_path;
    print "Successfully downloaded $distro->{name}\n";
    configure_rootfs();
}

sub configure_rootfs {
    
    my $username;
    while (!$username) {
        print "Enter username for new user: ";
        chomp($username = <STDIN>);
        if (!$username) {
            print "Username cannot be empty\n";
        }
    }
    
    my $admin_group = "";
    if (-f "$ROOTFS_DIR/etc/group") {
        open my $group_fh, '<', "$ROOTFS_DIR/etc/group" or die "Cannot open group file: $!\n";
        my $group_content = do { local $/; <$group_fh> };
        close $group_fh;
        
        if ($group_content =~ /^wheel:/m) {
            $admin_group = "wheel";
        } elsif ($group_content =~ /^sudo:/m) {
            $admin_group = "sudo";
        }
    }
    
    my $useradd_cmd = "$BASE_DIR/tools/useradd --root \"$ROOTFS_DIR\" -U -s /bin/bash";
    $useradd_cmd .= " -G $admin_group" if $admin_group;
    $useradd_cmd .= " \"$username\"";
    
    system($useradd_cmd) == 0 or die "Failed to create user: $!\n";

    make_path("$ROOTFS_DIR/home/$username");

    my @accounts = (
        { name => $username, label => "user '$username'" },
        { name => "root", label => "root" }
    );
    
    for my $account (@accounts) {
        my $passwd_success = 0;
        while (!$passwd_success) {
            print "Enter password for $account->{label}: ";
            system("stty -echo");
            chomp(my $password = <STDIN>);
            system("stty echo");
            print "\n";
            if ($password) {
                my $mkpasswd_cmd = "echo '$password' | $BASE_DIR/tools/mkpasswd -s";
                my $passwd_hash = `$mkpasswd_cmd`;
                chomp($passwd_hash);
                
                if ($? == 0 && $passwd_hash) {
                    my $sed_cmd = "sed -i 's|^$account->{name}:[!*]*:|$account->{name}:$passwd_hash:|' \"$ROOTFS_DIR/etc/shadow\"";
                    if (system($sed_cmd) == 0) {
                        $passwd_success = 1;
                    }
                }
            } else {
                print "Password cannot be empty\n";
            }
        }
    }
    
    if (-f "/etc/hostname") {
        system("cp", "/etc/hostname", "$ROOTFS_DIR/etc/hostname")
    }
}

sub clean {
    must_be_root("clean");
    if (-d $BASE_DIR) {
        print "Cleaning files...\n";
        remove_tree($BASE_DIR);
        print "Distrousurp files have been cleaned.\n";
    } else {
        print "Distrousurp files do not exist.\n";
    }
}

sub boot {
    must_be_root("boot");
    my @extra_args = @_;
    
    # Check if kexec is disabled
    open my $kexec_fh, '<', '/proc/sys/kernel/kexec_load_disabled' or die "Cannot open /proc/sys/kernel/kexec_load_disabled: $!";
    my $kexec_disabled = <$kexec_fh>;
    chomp($kexec_disabled);
    close $kexec_fh;
    
    if ($kexec_disabled == 1) {
        print STDERR "Kexec disabled. Boot with 'kexec_load_disabled=0'\n";
        exit 1;
    }
    
    if (-f "$ROOTFS_DIR/sbin/init") {
        open my $cmdline_fh, '<', '/proc/cmdline' or die "Cannot open /proc/cmdline: $!";
        my $cmdline = <$cmdline_fh>;
        chomp($cmdline);
        close $cmdline_fh;

        # Carry on our root param
        # Need RW within the initramfs to copy files and mount /old_root
        # Some distros don't know how they've booted and assume efi, that is wrong
        # Don't remount our FS, we don't need it
        # SELinux is disabled because I didn't configure it for each distro
        my @params = ($cmdline =~ /(root=[^ ]*|rd\.[^ ]*)/g);
        my $commandline = join(' ', @params);
        $commandline .= " rw fbcon=nodefer systemd.mask=boot-efi.mount systemd.mask=efi.mount systemd.mask=systemd-remount-fs.service selinux=0 ";
        $commandline .= join(' ', @extra_args) if @extra_args;

        my $sync_cmd = "sync";
        my $kexec_cmd = "$BASE_DIR/tools/kexec -afd --initrd=$BASE_DIR/kernel/initramfs.cpio.zst --no-ifdown --command-line=\"$commandline\" $BASE_DIR/kernel/bzImage";
        system($sync_cmd);
        system($kexec_cmd);
        my $exit_code = $? >> 8;
        if ($exit_code != 0) {
            print "Warning: kexec exited with code $exit_code\n";
        }
    } else {
        die "No valid rootfs found. Run 'distrousurp fetch <ID>' first.\n";
    }
}

my $command = shift @ARGV || 'help';
if ($command eq 'update') {
    update();
} elsif ($command eq 'list') {
    list();
} elsif ($command eq 'fetch') {
    my $id = shift @ARGV;
    fetch($id);
} elsif ($command eq 'clean') {
    clean();
} elsif ($command eq 'boot') {
    boot(@ARGV);
} else {
    print <<USAGE;
Usage: distrousurp <command>

Commands:
  update           Download the latest distros.json
  list             List available distributions
  fetch [ID]       Download and extract a distribution
  clean            Remove the rootfs directory
  boot [kargs...]  Boot the current rootfs with optional kernel arguments
USAGE
}