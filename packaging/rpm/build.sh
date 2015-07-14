#!/usr/bin/env sh
# Build the ODL SRPM and noarch RPM described in opendaylight.spec
# This is designed to be run in the included Vagrant environment.

# Echo commands as they are run
set -x

# NB: These will need to be updated for version bumps
odl_version="0.3.0-Lithium"
rpm_version="3.0.0"
rpm_release=1
sysd_commit="4a87227"

# Common names used in this script
odl_srpm="opendaylight-$rpm_version-$rpm_release.src.rpm"
odl_rpm="opendaylight-$rpm_version-$rpm_release.noarch.rpm"
odl_tarball="distribution-karaf-$odl_version.tar.gz"
unitfile_tarball="opendaylight-systemd-$sysd_commit.tar.gz"

# Common paths used in this script
odl_tb_cache_path="/vagrant/$odl_tarball"
unitfile_cache_path="/vagrant/$unitfile_tarball"
srpm_out_path="$HOME/rpmbuild/SRPMS/$odl_srpm"
rpm_out_path="$HOME/rpmbuild/RPMS/noarch/$odl_rpm"
odl_tb_url="https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/$odl_version/$odl_tarball"
unitfile_url="https://github.com/dfarrell07/opendaylight-systemd/archive/$sysd_commit/$unitfile_tarball"
rpmbuild_src_dir="$HOME/rpmbuild/SOURCES/"
rpmbuild_spec_dir="$HOME/rpmbuild/SPECS/"

# Install required software, add user to mock group for rpmbuild
sudo yum install -y @development-tools fedora-packager
sudo usermod -a -G mock $USER

# Configure rpmbuild dir
rpmdev-setuptree

# Download ODL release tarball if it's not cached locally already
if [ ! -f  $odl_tb_cache_path ]; then
    echo "No cached ODL found, downloading from Nexus..."
    curl -o $odl_tb_cache_path $odl_tb_url
else
    echo "Using cached version of ODL at $odl_tb_cache_path"
fi

# Put ODL release tarball in the location required by rpmbuild
cp $odl_tb_cache_path $rpmbuild_src_dir

# Put systemd unit file archive in rpmbuild's SOURCES dir
# Need `-L` to follow redirects
curl -L -o $rpmbuild_src_dir/$unitfile_tarball $unitfile_url

# Put ODL RPM .spec file in location required by rpmbuild
cp opendaylight.spec $rpmbuild_spec_dir

# Build ODL SRPM and noarch RPM
cd $rpmbuild_spec_dir
rpmbuild -ba opendaylight.spec

# Confirm SRPM found in expected location
if [ -f  $srpm_out_path ]; then
    echo "SRPM built!"
    echo "Location: $srpm_out_path"
    if [ -d  /vagrant/ ]; then
        echo "Assuming you want to move RPM off Vagrant box"
        cp $srpm_out_path /vagrant/
    fi
else
    echo "SRPM seems to have failed. :(" >&2
fi

# Confirm RPM found in expected location
if [ -f  $rpm_out_path ]; then
    echo "RPM built!"
    echo "Location: $rpm_out_path"
    if [ -d  /vagrant/ ]; then
        echo "Assuming you want to move RPM off Vagrant box"
        cp $rpm_out_path /vagrant/
    fi
else
    echo "RPM seems to have failed. :(" >&2
fi
