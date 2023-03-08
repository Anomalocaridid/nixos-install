#!/usr/bin/env bash

# Config constants
readonly DISK="/dev/vda"
readonly MEMORY="8G"
readonly KEYFILE="/tmp/passphrase.txt"

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

# NOTE: Run directly as command after next stable nixpkgs release
readonly DISKO_COMMAND="nix run github:nix-community/disko \
	--extra-experimental-features nix-command \
	--extra-experimental-features flakes \
	-- \
	--mode zap_create_mount /tmp/disko-config.nix \
	--argstr disk $DISK \
	--argstr memory $MEMORY \
	--argstr keyFile $KEYFILE" # || exit 1

# NOTE: Remove after next stable nixpkgs release
# Necessary because btrfs-progs 6.1 or higher is needed to create swapfile
nix-shell -p btrfs-progs \
	-I nixpkgs=https://github.com/NixOS/nixpkgs/archive/master.tar.gz \
	--run "$DISKO_COMMAND" || exit 1

# Activate swap subvolume created by disko
# Necessary because doing it during postCreateHook makes disk busy
# and messes up partitioning because disko needs to unmount subvolumes after creation
echo "Activating swapfile"
swapon /mnt/swap/swapfile || exit 1
