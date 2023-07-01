#!/bin/bash

# Switch to root user
sudo -i

# Partitioning
gdisk /dev/nvme0n1 <<EOF
o
n
1
2048
+512M
ef00
n
2


8e00
w
Y
EOF

# Setup the encrypted LUKS partition and open it
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup config /dev/nvme0n1p2 --label cryptroot
cryptsetup luksOpen /dev/nvme0n1p2 enc

# Create logical volumes
pvcreate /dev/mapper/enc
vgcreate vg /dev/mapper/enc
lvcreate -L 24G -n swap vg
lvcreate -l '100%FREE' -n root vg

# Format partitions
mkfs.fat -F 32 -n boot /dev/nvme0n1p1
mkswap -L swap /dev/vg/swap
swapon /dev/vg/swap
mkfs.btrfs -L root /dev/vg/root

# Mount partitions
mount -t btrfs /dev/vg/root /mnt

# Create the subvolumes
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/log
umount /mnt

# Mount the directories
mount -o subvol=root,compress=zstd,noatime,ssd,space_cache=v2 /dev/vg/root /mnt
mkdir -p /mnt/{home,nix,var/log}
mount -o subvol=home,compress=zstd,noatime,ssd,space_cache=v2 /dev/vg/root /mnt/home
mount -o subvol=nix,compress=zstd,noatime,ssd,space_cache=v2 /dev/vg/root /mnt/nix
mount -o subvol=log,compress=zstd,noatime,ssd,space_cache=v2 /dev/vg/root /mnt/var/log

# Mount boot partition
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

# Enable flakes
nix-shell -p nixFlakes
