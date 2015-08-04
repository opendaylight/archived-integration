#!/usr/bin/env sh
# Simple helper script for uninstalling ODL

# Echo commands as they are run
set -x

# Uninstall ODL
echo "Uninstalling ODL"
sudo rpm -e opendaylight
