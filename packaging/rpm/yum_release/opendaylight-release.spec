# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

%if 0%{?rhel}
%define YUMREPO epel-%{rhel}-x86_64
%else
%define YUMREPO fedora-%{fedora}-x86_64
%endif

Name:           opendaylight-release
Version:        0.1.0
Release:        2%{?dist}
Summary:        OpenDaylight Repository Configuration

Group:          System Environment/Base
License:        EPL
URL:            http://www.opendaylight.org
Source0:        opendaylight.repo
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires:  sed
BuildArch:      noarch

%description
The OpenDaylight repository contains RPMs for installing the
OpenDaylight components on a system.

%install
rm -rf %{buildroot}
%{__mkdir} -p %{buildroot}%{_sysconfdir}/yum.repos.d
sed 's/MOCKENV/%{YUMREPO}/g' %{SOURCE0} > %{buildroot}%{_sysconfdir}/yum.repos.d/opendaylight.repo

%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%{_sysconfdir}/yum.repos.d/*.repo

%endif

%changelog
* Mon Jan 27 2014 Andrew Grimberg <agrimberg@linuxfoundation.org> - 0.1.0-2
- Fix fedora releas packages to have correct URL

* Wed Jan 22 2014 Andrew Grimberg <agrimberg@linuxfoundation.org> - 0.1.0-1
- Initial packaging
