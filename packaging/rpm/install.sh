#!/usr/bin/env sh
# Simple helper script for installing ODL from its noarch RPM

# Echo commands as they are run
set -x

# Extract optional cache dir argument, default to `/vagrant`
if [[ $# -eq 0 ]]; then
  echo "Defaulting to /vagrant as cache_dir"
  cache_dir="/vagrant"
elif [[ $# -eq 1 ]]; then
  cache_dir=$1
else
  echo "Usage: $0 [cache dir]" >&2
  exit 1
fi

# NB: These will need to be updated for version bumps
rpm_version="3.0.0"
rpm_release="2.el7"
odl_rpm="opendaylight-$rpm_version-$rpm_release.noarch.rpm"
rpm_path="$cache_dir/$odl_rpm"

# Install Java, required by ODL
sudo yum install -y java

# Install ODL
echo "Installing ODL from $rpm_path"
sudo rpm -i $rpm_path
