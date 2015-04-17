#!/usr/bin/env sh

# Update version/path if needed
rpm_path="./opendaylight-0.2.3-2.noarch.rpm"

# Install ODL
echo "Installing ODL from $rpm_path"
sudo rpm -i $rpm_path
