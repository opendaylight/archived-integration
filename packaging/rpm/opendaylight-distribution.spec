# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight-distribution
Version: 0.1.0
Release: 0.2.0%{?dist}
Summary: OpenDaylight SDN Controller Distributions
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org
BuildArch: noarch

Requires: opendaylight-controller
Requires: opendaylight-ovsdb
Requires: opendaylight-controller-dependencies

%description
OpenDaylight SDN Controller Distributions

%files

%endif

%changelog
* Thu Jan 09 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.5.0
- Updates for OF1.3 support.
- Remove java Requires.

* Thu Jan 02 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.1.0
- Initial package.
