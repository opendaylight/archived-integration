# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight-distribution
Version: 0.1.0
Release: 0.1.0%{?dist}
Summary: OpenDaylight SDN Controller Distributions
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org
BuildArch: noarch

Requires: java >= 1:1.7.0
Requires: opendaylight-controller
Requires: opendaylight-ovsdb
Requires: opendaylight-controller-dependencies

%description
OpenDaylight SDN Controller Distributions

%files

%endif

%changelog
* Thu Jan 02 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.1.0
- Initial package.
