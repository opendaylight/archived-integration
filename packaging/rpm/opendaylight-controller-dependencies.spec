Name: opendaylight-controller-dependencies
Version: 0.1.0
Release: 0.3.0%{?dist}
Summary: OpenDaylight SDN Controller Dependencies
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org

# The sources are built by the other projects so just copy them:
# cp ~/rpmbuild/BUILD/opendaylight-controller-0.1.0/opendaylight/distribution/opendaylight/target/distribution.opendaylight-osgipackage.zip ~/rpmbuild/SOURCES/opendaylight-controller-%{version}.zip
# cp ~/rpmbuild/BUILD/opendaylight-ovsdb-0.1.0/distribution/opendaylight/target/distribution.ovsdb-1.0.0-SNAPSHOT-osgipackage.zip ~/rpmbuild/SOURCES/opendaylight-ovsdb-%{version}.zip
Source0: opendaylight-controller-%{version}.zip
Source1: opendaylight-ovsdb-%{version}.zip
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

%setup -q -c -c -n opendaylight-controller-dependencies-%{version}
%setup -q -T -a 1 -c -n opendaylight-ovsdb-dependencies-%{version}


%build
exit 0


%install

mv -f ../opendaylight-controller-dependencies-%{version}/opendaylight/lib/* opendaylight/lib/
mv -f ../opendaylight-controller-dependencies-%{version}/opendaylight/plugins/* opendaylight/plugins/

# Create the directory for the dependencies:
mkdir -p %{buildroot}%{deps_dir}

for src in $( ls -I "org.opendaylight.*" opendaylight/lib );
do
    #tgt=$(echo ${src} | sed -e "s/-[0-9].*/.jar/")
    #mv opendaylight/lib/${src} %{buildroot}%{deps_dir}/${tgt}
    mv opendaylight/lib/${src} %{buildroot}%{deps_dir}/${src}
done

for src in $( ls -I "org.opendaylight.*" opendaylight/plugins );
do
    #tgt=$(echo ${src} | sed -e "s/-[0-9].*/.jar/")
    #mv opendaylight/plugins/${src} %{buildroot}%{deps_dir}/${tgt}
    mv opendaylight/plugins/${src} %{buildroot}%{deps_dir}/${src}
done


%files

# Own the directory containing the dependencies and its contents:
%{deps_dir}


%changelog
* Thu Jan 02 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.3.0
- Updates to include building distributions.

* Fri Nov 22 2013 Sam Hague <shague@redhat.com> - 0.1.0-0.2.0
- Updates to support building rpm with jenkins.

* Fri Nov 01 2013 Sam Hague <shague@redhat.com> - 0.1.0-0.1.20131007git31c8f18
- Initial Fedora package.
