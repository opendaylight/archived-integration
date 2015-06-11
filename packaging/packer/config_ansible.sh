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

# Install the latest release of ODL's Ansible role from Ansible Galaxy
# The `ansible-galaxy` tool was installed by Ansible's RPM
# NB: This could also be done by locally installing ODL's role, then
#     giving Packer it's local path via the role_paths argument to the
#     ansible-local provisioner. However, that approach requires a
#     step not managed by Packer (installing the role, which shouldn't
#     be checked into VCS, locally). Not only does that break the
#     model of being able to build directly from what's in VCS, it
#     breaks pushes to do automated remote builds. We can/should only
#     push what's version controlled, and we can't install the role
#     pre-build manually on the remote host, so we have to let Packer
#     own the ODL role install.
sudo ansible-galaxy install dfarrell07.opendaylight

# Clean up to save space
sudo yum clean all -y
sudo rm -rf /tmp/*
