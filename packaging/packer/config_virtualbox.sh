#!/usr/bin/env bash
# Called by packer to install VirtualBox Guess Additions, which
# required by Vagrant for things like mounting shared dirs.

# Echo commands as they are run
set -x

# Install utilities required by VB Guest Additions install
sudo yum install -y bzip2 gcc kernel-devel

# Install VirtualBox Guest Additions (downloaded by Packer)
sudo mount -o loop /home/vagrant/VBoxGuestAdditions.iso /mnt
sudo /mnt/VBoxLinuxAdditions.run

# Clean up VirtualBox Guest Additions install media to save space
sudo umount /mnt
rm -rf /home/vagrant/VBoxGuestAdditions.iso
