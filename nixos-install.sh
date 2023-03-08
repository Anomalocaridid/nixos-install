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
# Create swapfile
echo "Creating swapfile"
# NOTE: After next stable release, get rid of nix-shell invocation and run command directly
# Use latest btrfs-progs
nix-shell -p btrfs-progs \
	-I nixpkgs=https://github.com/NixOS/nixpkgs/archive/master.tar.gz \
	--run "btrfs filesystem mkswapfile --size $MEMORY /mnt/swap/swapfile" ||
	exit 1
swapon /mnt/swap/swapfile || exit 1
