#!/usr/bin/env sh

# Update version if needed
rpm_name="opendaylight-0.2.3"

# Uninstall ODL
echo "Uninstalling $rpm_name"
sudo rpm -e opendaylight-0.2.3
