#!/usr/bin/env sh

# Common paths used in this script
# NB: Name will need to be updated for both ODL and RMP version bumps
rpm_name="opendaylight-0.2.2-1.fc20.noarch.rpm"
rpm_out_path="$HOME/rpmbuild/RPMS/noarch/$rpm_name"
src_name="distribution-karaf-0.2.2-Helium-SR2.tar.gz"
src_cache_path0="$HOME/$src_name"
src_cache_path1="/vagrant/$src_name"
sysd_commit=f984005

# Install required software, add user to mock group for rpmbuild
sudo yum install -y @development-tools fedora-packager
sudo usermod -a -G mock $USER

# Configure rpmbuild dir
rpmdev-setuptree

# Put ODL source archive location required by rpmbuild
if [ -f  $src_cache_path0 ]; then
    echo "Using cached version of ODL at $src_cache_path0"
    cp $src_cache_path0 $HOME/rpmbuild/SOURCES/$src_name
elif [ -f  $src_cache_path1 ]; then
    echo "Using cached version of ODL at $src_cache_path1"
    cp $src_cache_path1 $HOME/rpmbuild/SOURCES/$src_name
else
    echo "No cached ODL found, downloading from Nexus..."
    curl -o $HOME/rpmbuild/SOURCES/$src_name https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.2.2-Helium-SR2/$src_name
fi

# Put systemd unit file archive in rpmbuild's SOURCES dir
# Need `-L` to follow redirects
curl -L -o $HOME/rpmbuild/SOURCES/opendaylight-systemd-$sysd_commit.tar.gz https://github.com/dfarrell07/opendaylight-systemd/archive/$sysd_commit/opendaylight-systemd-$sysd_commit.tar.gz

# Put ODL RPM .spec file in location required by rpmbuild
cp opendaylight.spec $HOME/rpmbuild/SPECS

# Build ODL RPM
cd $HOME/rpmbuild/SPECS
rpmbuild -ba opendaylight.spec

# Confirm RPM found in expected location
if [ -f  $rpm_out_path ]; then
    echo "RPM built!"
    echo "Should be at: $rpm_out_path"
else
    echo "RPM seems to have failed. :(" &>2
fi
