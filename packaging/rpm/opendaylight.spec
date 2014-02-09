# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight
Version: 0.1.0
Release: 0.5.0%{?dist}
Summary: OpenDaylight SDN Controller Platform
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org
BuildArch: noarch

Requires: opendaylight-controller
Requires: opendaylight-controller-dependencies
Requires: opendaylight-openflowjava
Requires: opendaylight-openflowplugin
Requires: opendaylight-ovsdb
Requires: opendaylight-yangtools

%description
The OpenDaylight SDN Controller Platform provides the core
services and abstractions needed for building an SDN controller.

The Base edition of OpenDaylight is designed for testing and experimental
purposes.

%package virtualization
Summary: OpenDaylight SDN Controller Platform Virtualization Edition
Group: Applications/Communications
Requires: %{name}
#Requires: opendaylight-affinity
#Requires: opendaylight-defense4all
#Requires: opendaylight-opendove
#Requires: opendaylight-opendove-odmc
#Requires: opendaylight-vtn

%description virtualization
The Virtualization edition of OpenDaylight is geared towards data centers.
It includes the OVSDB protocol southbound and the Affinity Service, VTN,
DOVE, and the OpenStack Service.

%package serviceprovider
Summary: OpenDaylight SDN Controller Platform Virtualization Edition
Group: Applications/Communications
Requires: %{name}
#Requires: opendaylight-affinity
#Requires: opendaylight-bgpcep
#Requires: opendaylight-defense4all
Requires: opendaylight-lispflowmapping
#Requires: opendaylight-snmp4sdn

%description serviceprovider
The Service Provider edition of OpenDaylight is designed for network operator
use. It does not include OVSDB, VTN or DOVE, but does include SNMP, BGP-LS,
PCEP, and LISP southbound and the Affinity Service and the LISP Service northbound.

%files

%files virtualization

%files serviceprovider

%endif

%changelog
* Sat Feb 08 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.5.0
- Add yangtools package.

* Sat Feb 01 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.4.0
- Changed package name to opendaylight.
- Added edition sub packages.

* Sat Jan 18 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.3.0
- Removed controller-dependencies from Requires because controller already pulls it in.

* Thu Jan 09 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.2.0
- Updates for OF1.3 support.
- Remove java Requires.

* Thu Jan 02 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.1.0
- Initial package.
