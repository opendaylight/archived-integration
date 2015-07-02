#!/usr/bin/env bash
# Install Ansible, as required for Packer's ansible-local provisioner.
# Also installs EPEL (dependency).

# Echo commands as they are run
set -x

# Install EPEL for access to Ansible repo
# EPEL is okay to bake in, good minimization vs functionality trade-off
sudo yum install -y epel-release

# Install Ansible, required for Packer's ansible-local provisioner
# Git is required by the ansible-galaxy tool when installing roles
sudo yum install -y ansible git

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
# NB: The simple `ansible-galaxy install <role>[,version]` syntax doesn't
#     support versions other than those on Ansible Galaxy, so tags. The
#     `ansible-galaxy` command will accept more complex versions via a
#     requirements.yml file, however. Using that to support branches,
#     commits, and tags. See: http://stackoverflow.com/a/30176625/1011749
# TODO: Pass this version var from packer_vars.json
ansible_version="origin/master"
cat > /tmp/requirements.yml << EOM
- name: opendaylight
  src: https://github.com/dfarrell07/ansible-opendaylight
  version: $ansible_version
EOM
sudo ansible-galaxy install -r /tmp/requirements.yml

# Clean up to save space
# NB: The point of this script is to leave Ansible and ODL's role installed
#     and ready for use by the Packer Ansible provisioner, so we can't clean
#     up that space here. Need to clean it up in a post-install cleanup script.
sudo yum remove -y git
sudo yum clean all -y
sudo rm -rf /tmp/*
