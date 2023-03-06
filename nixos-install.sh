#!/usr/bin/env bash

# Config constants
DISK="/dev/vda"
MEMORY="8G"
KEYFILE="/tmp/passphrase.txt"

# Prompt for password
while true; do
	read -r -s -p "Encryption password: " password </dev/tty
	echo ""
	read -r -s -p "Encryption password (again): " password2 </dev/tty
	echo ""

	if [[ $password == "$password2" ]]; then
		if [[ -z $password ]]; then
			echo "ERROR: Password is empty. Please enter a different password."
		else
			break
		fi
	else
		echo "ERROR: Passwords do not match. Please re-enter password."
	fi
done

echo "$password" >$KEYFILE

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
	--argstr disk "$DISK" \
	--argstr keyFile "$KEYFILE" ||
	exit 1

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
