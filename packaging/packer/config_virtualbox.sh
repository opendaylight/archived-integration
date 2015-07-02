#!/usr/bin/env bash
# Called by packer to install VirtualBox Guess Additions, which
# required by Vagrant for things like mounting shared dirs.

# Echo commands as they are run
set -x

# Install utilities required by VB Guest Additions install
# TODO: Is all of @Base and @Core strictly required?
sudo yum install -y @Base @Core bzip2 gcc kernel-devel

# Install VirtualBox Guest Additions (downloaded by Packer)
sudo mount -o loop /home/vagrant/VBoxGuestAdditions.iso /mnt
sudo /mnt/VBoxLinuxAdditions.run

# Clean up VirtualBox Guest Additions install media to save space
sudo umount /mnt
rm -rf /home/vagrant/VBoxGuestAdditions.iso
sudo rm -rf /usr/src/vboxguest*

# Clean up utilities required by VB Guest Additions install to save space
# Don't remove bzip2, it's only 87k. Removing gcc saves 37M, kernel-devel 32M.
sudo yum remove -y gcc kernel-devel
sudo yum clean all -y
sudo rm -rf /tmp/*
