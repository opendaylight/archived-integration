#!/usr/bin/env sh

# Update if needed
rpm_path="$HOME/rpmbuild/RPMS/noarch/opendaylight-0.2.1-5.fc20.noarch.rpm"

# Install ODL
echo "Installing ODL"
sudo rpm -i $rpm_path
