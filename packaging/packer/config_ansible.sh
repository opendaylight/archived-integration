#!/usr/bin/env bash
# Install Ansible, as required for Packer's ansible-local provisioner.
# Also installs EPEL (dependency).

# Echo commands as they are run
set -x

# Install EPEL for access to Ansible repo
# EPEL is okay to bake in, good minimization vs functionality trade-off
sudo yum install -y epel-release

# Install Ansible, required for Packer's ansible-local provisioner
sudo yum install -y ansible

# Clean up to save space
sudo yum clean all -y
sudo rm -rf /tmp/*
