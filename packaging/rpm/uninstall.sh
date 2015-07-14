#!/usr/bin/env sh
# Simple helper script for uninstalling ODL

# Echo commands as they are run
set -x

# NB: These will need to be updated for version bumps
rpm_version="3.0.0"

# Uninstall ODL
echo "Uninstalling ODL"
sudo rpm -e opendaylight-$rpm_version
