#!/bin/bash

# Create logical volumes
pvcreate /dev/mapper/enc
sleep 0.2
vgcreate vg /dev/mapper/enc
sleep 0.2
lvcreate -L 24G -n swap vg
sleep 0.2
lvcreate -l '100%FREE' -n root vg
sleep 0.2

# Format partitions
mkfs.fat -F 32 -n boot /dev/nvme0n1p1
sleep 0.2
mkswap -L swap /dev/vg/swap
sleep 0.2
swapon /dev/vg/swap
sleep 0.2
mkfs.btrfs -L root /dev/vg/root
sleep 0.2

# Mount partitions
mount -t btrfs /dev/vg/root /mnt
sleep 0.2

# Create the subvolumes
btrfs subvolume create /mnt/root
sleep 0.2
btrfs subvolume create /mnt/home
sleep 0.2
btrfs subvolume create /mnt/nix
sleep 0.2
btrfs subvolume create /mnt/log
sleep 0.2
umount /mnt
sleep 0.2

# Mount the directories
mount -o subvol=root,compress=zstd,noatime,ssd,space_cache=v2 /dev/vg/root /mnt
sleep 0.2
mkdir -p /mnt/{home,nix,var/log}
sleep 0.2
mount -o subvol=home,compress=zstd,noatime,ssd,space_cache=v2 /dev/vg/root /mnt/home
sleep 0.2
mount -o subvol=nix,compress=zstd,noatime,ssd,space_cache=v2 /dev/vg/root /mnt/nix
sleep 0.2
mount -o subvol=log,compress=zstd,noatime,ssd,space_cache=v2 /dev/vg/root /mnt/var/log
sleep 0.2

# Mount boot partition
mkdir /mnt/boot
sleep 0.2
mount /dev/nvme0n1p1 /mnt/boot
sleep 0.2

# Enable flakes
nix-shell -p nixFlakes