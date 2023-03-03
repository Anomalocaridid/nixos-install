#!/usr/bin/env bash

# Config constants
readonly DISK
DISK="/dev/vda1"

readonly MEMORY
MEMORY="8G"

# Download disko config
echo "Downloading disko config"
curl https://raw.githubusercontent.com/Anomalocaridid/nixos-dotfiles/main/disko-config.nix
\  >/tmp/disko-config.nix

# Partition disk with disko
echo "Partitioning disk with disko"
nix run github:nix-community/disko
\ --extra-experimental-features nix-command
\ --extra-experimental-features flake
\ --
\ --mode zap_create_mount /tmp/disko-config.nix
\ --arg disks "[ '$DISK' ]"
# \ --arg memory 'MEMORY'

# NOTE: Move to disko config if feasible
# Create blank subvolume
echo "Creating blank root subvolume"
btrfs subvolume snapshot /mnt /mnt/root-blank

# NOTE: Remove from script after next stable release
# Install latest btrfs-progs
# Needed for swapfile commands
echo "Installing latest btrfs-progs"
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --update
nix-env -iA nixos-unstable.btrfs-progs

# NOTE: Move to disko config if feasible
# Create swapfile
echo "Creating swapfile"
btrfs filesystem mkswapfile --size "$MEMORY" /mnt/swap/swapfile
swapon /mnt/swap/swapfile
