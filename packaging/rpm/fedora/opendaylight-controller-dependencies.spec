Name: opendaylight-controller-dependencies
Version: 0.1.0
Release: 0.1.20131101git31c8f18%{?dist}
Summary: OpenDaylight SDN Controller Dependencies
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org
Source: opendaylight-controller-%%{version}.zip
BuildArch: noarch
Requires: java >= 1:1.7.0

# Here you should have at least dependencies for the packages containing .jar
# files that you want to create symlinks to:
# First pass just use everything from the distribution zip.
#Requires: slf4j

# This is the directory where all dependencies will go:
# /usr/share/java/opendaylight-controller-dependencies
%global deps_dir %{_javadir}/%{name}

%description
OpenDaylight SDN Controller Dependencies


%prep
%setup -q -c opendaylight-controller-dependencies-%{version}


%build

# Nothing to build, just repackage the jars
exit 0


%install

# Create the directory for the dependencies:
mkdir -p %{buildroot}%{deps_dir}

for src in $( ls -I "org.opendaylight.*" opendaylight/lib );
do
    tgt=$(echo ${src} | sed -e "s/-[0-9].*/.jar/")
    mv opendaylight/lib/${src} %{buildroot}%{deps_dir}/${tgt}
done

for src in $( ls -I "org.opendaylight.*" opendaylight/plugins );
do
    tgt=$(echo ${src} | sed -e "s/-[0-9].*/.jar/")
    mv opendaylight/plugins/${src} %{buildroot}%{deps_dir}/${tgt}
done


%files

# Own the directory containing the dependencies and its contents:
%{deps_dir}


%changelog
* Fri Nov 01 2013 Sam Hague <shague@redhat.com> - 0.1.0-0.1.20131007git31c8f18
- Initial Fedora package.
