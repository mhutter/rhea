#!/usr/bin/env bash
set -e -u -o pipefail -x

lsblk

# Undo any previous changes
set +e
umount -R /mnt
cryptsetup close cryptroot
vgchange -an
set -e

# prevent mdadm from auto-assembling any preexisting arrays
mdadm --stop --scan
echo 'AUTO -all
ARRAY <ignore> UUID=00000000:00000000:00000000:00000000' > /etc/mdadm/mdadm.conf

# partitioning
for disk in /dev/nvme?n1; do
  parted --script --align=optimal "$disk" -- mklabel msdos
  parted --script --align=optimal "$disk" -- mkpart primary ext4 1M 1G
  parted --script --align=optimal "$disk" -- set 1 boot on
  parted --script --align=optimal "$disk" -- mkpart primary ext4 1GB '100%'
done

# reload partition table
partprobe || :
udevadm settle --timeout=5s --exit-if-exists=/dev/nvme0n1p1
udevadm settle --timeout=5s --exit-if-exists=/dev/nvme0n1p2
udevadm settle --timeout=5s --exit-if-exists=/dev/nvme1n1p1
udevadm settle --timeout=5s --exit-if-exists=/dev/nvme1n1p2

# wipe any previous RAID signatures
mdadm --zero-superblock --force /dev/nvme0n1p2
mdadm --zero-superblock --force /dev/nvme1n1p2

# create RAID
mdadm --create --run --verbose \
  /dev/md0 \
  --name=md0 \
  --level=raid1 --raid-devices=2 \
  --homehost=rhea  \
  /dev/nvme0n1p2 \
  /dev/nvme1n1p2

# remove traces from preexisting filesystems etc
vgchange -an
wipefs -a /dev/md0

echo 0 > /proc/sys/dev/raid/speed_limit_max

# set up encryption
cryptsetup -q -v luksFormat /dev/md0
cryptsetup -q -v open /dev/md0 cryptroot

# create filesystems
mkfs.ext4 -F -L boot0 /dev/nvme0n1p1
mkfs.ext4 -F -L boot1 /dev/nvme1n1p1
mkfs.ext4 -F -L nix -m 0 /dev/mapper/cryptroot

# refres disk/by-uuid entries
udevadm trigger
udevadm settle --timeout=5 --exit-if-exists=/dev/disk/by-label/nix

# mount filesystems
mount -t tmpfs none /mnt

mkdir -pv /mnt/{boot,boot-fallback,nix,etc/{nixos,ssh},var/{lib,log},srv}

mount /dev/disk/by-label/boot0 /mnt/boot
mount /dev/disk/by-label/boot1 /mnt/boot-fallback
mount /dev/disk/by-label/nix   /mnt/nix

mkdir -pv /mnt/nix/{secret/initrd,persist/{etc/{nixos,ssh},var/{lib,log},srv}}
chmod 0700 /mnt/nix/secret

mount -o bind /mnt/nix/persist/etc/nixos /mnt/etc/nixos
mount -o bind /mnt/nix/persist/var/log   /mnt/var/log

# Install Nix
apt-get update
apt-get install -y sudo
mkdir -p /etc/nix
echo "build-users-group =" >> /etc/nix/nix.conf
curl -sSL https://nixos.org/nix/install | sh
set +u +x # sourcing this may refer to unset variables that we have no control over
. "$HOME/.nix-profile/etc/profile.d/nix.sh"
set -u -x

nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
nix-channel --update

# Getting NixOS installation tools
nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter ]"

# generated initrd SSH host keys
ssh-keygen -t ed25519 -N "" -C "" -f /mnt/nix/secret/initrd/ssh_host_ed25519_key

# TODO: prepare & copy NixOS configuration
#
# nixos-install --no-root-passwd --root /mnt --max-jobs 40
