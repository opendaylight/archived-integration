#!/usr/bin/env sh
# Simple helper script for installing ODL from its noarch RPM

# Echo commands as they are run
set -x

# NB: These will need to be updated for version bumps
rpm_version="3.0.0"
rpm_release=1
rpm_path="./opendaylight-$rpm_version-$rpm_release.noarch.rpm"

# Install Java, required by ODL
sudo yum install -y java

# Install ODL
echo "Installing ODL from $rpm_path"
sudo rpm -i $rpm_path
