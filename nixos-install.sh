#!/usr/bin/env bash

# Config constants
# readonly DISK
# DISK="/dev/vda1"

readonly MEMORY
MEMORY="8G"

# Download disko config
echo "Downloading disko config"
curl https://raw.githubusercontent.com/Anomalocaridid/nixos-dotfiles/main/disko-config.nix >/tmp/disko-config.nix || exit 1

# Partition disk with disko
echo "Partitioning disk with disko"
nix run github:nix-community/disko \
	--extra-experimental-features nix-command \
	--extra-experimental-features flakes \
	-- \
	--mode zap_create_mount /tmp/disko-config.nix \
	--arg disks '[ "/dev/vda1" ]' ||
	exit 1
# \ --arg memory 'MEMORY'

# NOTE: Move to disko config if feasible
# Create blank subvolume
echo "Creating blank root subvolume"
btrfs subvolume snapshot /mnt /mnt/root-blank || exit 1

# NOTE: Remove from script after next stable release
# Install latest btrfs-progs
# Needed for swapfile commands
echo "Installing latest btrfs-progs"
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable || exit 1
nix-channel --update || exit 1
nix-env -iA nixos-unstable.btrfs-progs || exit 1

# NOTE: Move to disko config if feasible
# Create swapfile
echo "Creating swapfile"
btrfs filesystem mkswapfile --size "$MEMORY" /mnt/swap/swapfile || exit 1
swapon /mnt/swap/swapfile || exit 1
