# jar_repack step takes a long time and doesn't seem to be necessary, so skip
%define __jar_repack 0

# Update this commit if systemd unit file is updated
%global commit 4a872270893f0daeebcbbcc0ff0014978e3c5f68
%global shortcommit %(c=%{commit}; echo ${c:0:7})

Name:       opendaylight
Version:    0.2.3
Release:    1%{?dist}
Summary:    OpenDaylight SDN Controller

Group:      Applications/Communications
License:    EPL-1.0
URL:        http://www.opendaylight.org
BuildArch:  noarch
Source0:    https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.2.3-Helium-SR3/distribution-karaf-0.2.3-Helium-SR3.tar.gz
Source1:    https://github.com/dfarrell07/opendaylight-systemd/archive/%{shortcommit}/opendaylight-systemd-%{shortcommit}.tar.gz
Buildroot:  /tmp

# Required for ODL at run time
Requires:   java >= 1:1.7.0
# Required for creating odl group
Requires(pre): shadow-utils
# Required for configuring systemd
BuildRequires: systemd

%pre
# Create `odl` user/group
# Short circuits if the user/group already exists
# Home dir must be a valid path for various files to be created in it
getent passwd odl > /dev/null || useradd odl -M -d $RPM_BUILD_ROOT/opt/%name
getent group odl > /dev/null || groupadd odl

%description
OpenDaylight Helium SR3 (0.2.3)

%prep
# Extract Source0 (ODL archive)
%autosetup -n distribution-karaf-0.2.3-Helium-SR3
# Extract Source1 (systemd config)
%autosetup -T -D -b 1 -n opendaylight-systemd-%{commit}

%install
# Create directory in build root for ODL
mkdir -p $RPM_BUILD_ROOT/opt/%name
# Move ODL from archive to its dir in build root
cp -r ../distribution-karaf-0.2.3-Helium-SR3/* $RPM_BUILD_ROOT/opt/%name
# Create directory in build root for systemd .service file
mkdir -p $RPM_BUILD_ROOT/%{_unitdir}
# Move ODL's systemd .service file to correct dir in build root
cp ../../BUILD/opendaylight-systemd-%{commit}/opendaylight.service $RPM_BUILD_ROOT/%{_unitdir}

%postun
# When the RPM is removed, the subdirs containing new files wouldn't normally
#   be deleted. Manually clean them up.
#   Warning: This does assume there's no data there that should be persevered
rm -rf $RPM_BUILD_ROOT/opt/%name

%files
# ODL will run as odl:odl, set as user:group for ODL dir, dont override mode
%attr(-,odl,odl) /opt/%name
# Configure systemd unitfile user/group/mode
%attr(0644,root,root) %{_unitdir}/%name.service


%changelog
* Mon Mar 23 2015 Daniel Farrell <dfarrell@redhat.com> - 0.2.3-1
- Upgrade from Helium SR2 to Helium SR3
* Sun Mar 15 2015 Daniel Farrell <dfarrell@redhat.com> - 0.2.2-4
- Don't override ODL dir mode, explicitly set unitfile owner:group
* Fri Mar 13 2015 Daniel Farrell <dfarrell@redhat.com> - 0.2.2-3
- Don't include ODL version in ODL dir name
* Tue Feb 10 2015 Daniel Farrell <dfarrell@redhat.com> - 0.2.2-2
- Bugfix in URL to download ODL systemd .service file
* Sat Jan 31 2015 Daniel Farrell <dfarrell@redhat.com> - 0.2.2-1
- Upgrade from Helium SR1.1 to Helium SR2
* Thu Jan 29 2015 Daniel Farrell <dfarrell@redhat.com> - 0.2.1-6
- Give odl user a valid home dir for automatically created files
* Tue Jan 13 2015 Daniel Farrell <dfarrell@redhat.com> - 0.2.1-5
- Set ODL ownership to odl:odl vs root:odl
* Mon Jan 12 2015 Daniel Farrell <dfarrell@redhat.com> - 0.2.1-4
- Added systemd config as a source
* Sat Jan 10 2015 Daniel Farrell <dfarrell@redhat.com> - 0.2.1-3
- Completely clean up ODL after uninstall
* Fri Jan 9 2015 Daniel Farrell <dfarrell@redhat.com> - 0.2.1-2
- Added systemd configuration
* Tue Dec 16 2014 Daniel Farrell <dfarrell@redhat.com> - 0.2.1-1
- Initial Karaf-based RPM
