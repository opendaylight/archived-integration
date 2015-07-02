#!/usr/bin/env bash
# Called by packer to do any Docker-specific config

# Echo commands as they are run
set -x

# Install minimal set of packages
# Need to do this as root but don't have sudo installed (Docker), so `su -c`
# The `sudo` program is needed by Ansible (so can't change it to use `su -c`)
# TODO: Is all of @Base strictly necessary?
su -c "yum install -y @Base sudo"

# Docker uses Ansible to configure ODL, and Ansible uses `sudo` so Docker's
# build will fail at Ansible without this config change (even if we removed it
# from subsequent Docker shell provisioning scripts).
su -c 'sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers'
