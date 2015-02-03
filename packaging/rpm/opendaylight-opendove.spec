# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight-opendove
Version: 0.1.0
Release: 0.3.0%{?dist}
Summary: OpenDaylight Open DOVE Virtualization Platform
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org



# todo: Temporary method for generating tarball
# git clone https://git.opendaylight.org/gerrit/p/ovsdb.git
# cd ovsdb
# git archive --prefix=opendaylight-ovsdb-0.1.0/ HEAD | xz > opendaylight-ovsdb-0.1.0.tar.xz
Source0: %{name}-%{version}.tar.xz

BuildArch: x86_64

BuildRequires: python-devel
BuildRequires: jansson-devel
BuildRequires: libevent-devel
BuildRequires: libnl-devel
BuildRequires: libuuid-devel
BuildRequires: openssl
BuildRequires: openssl-devel
BuildRequires: maven
BuildRequires: wget
Requires: java >= 1:1.7.0

# This is the directory where all the application resources (scripts,
# libraries, etc) will be installed: /usr/share/opendaylight
# for odmc component
%global resources_dir %{_datadir}/opendaylight-controller

# This is the directory that has all the JAVA dependencies.
# for odmc component
%global deps_dir %{_javadir}/opendaylight-controller-dependencies


%description
DOVE (distributed overlay virtual Ethernet) is a network
virtualization platform that provides isolated multi-tenant networks
on any IP network in a virtualized data center. DOVE consists of:
o  odmc - Open DOVE Management Console (OpenDaylight controller bundle)
o  odcs - Open DOVE Connectivity Server with clustering
o  ovs-agent - DOVE vswitch agent (works with Open vSwitch)
o  odgw - DOVE Gateway user agent (works with DOVE Gateway kernel module)


%package odmc
Summary: Open DOVE Management Console
Group: Applications/Communications
Buildarch: noarch

%description odmc 
The Open DOVE Management Console (DMC) provides a
REST API for programmatic virtual network management.  The DMC is also
used to configure the Open DOVE Gateway, the Open DOVE Connectivity
Server and and the DOVE vswitches.

%package ovs-agent
Summary: Open DOVE vswitch agent
Group: Applications/Communications

%description ovs-agent
User-level agent on each host that interfaces Open DOVE components to
the DOVE vswithes (based on Open vSwitch).  The DOVE vswitches
implement virtual networks by encapsulating tenant traffic in overlays
that span virtualized hosts in the data center, using the VxLAN frame
format.


%package odcs
Summary: Open DOVE Connectivity Server
Group: Applications/Communications

%description odcs

The Open DOVE Connectivity Server (DCS) supplies address and policy
information to individual Open DOVE vswitches.  The DCS also includes
support for high-availability and scale-out deployments through a
clustering protocol between replicated DCS instances.


%package odgw
Summary: Open DOVE Gateway
Group: Applications/Communications

%description odgw

The Open DOVE Gateway is a software-based gateway that allow traffic
to be exchanged between DOVE virtual networks and legacy IP or
Ethernet networks.  It operates in external or VLAN mode.  The DOVE
Gateway requires a kernel module to implement the forwarding path.

%prep

%setup -q


%build

cd odcs; make; cd ..
cd odgw; make; cd ..
cd third-party; ./getdeps.sh; cd ..
cd ovs-agent; make; cd ..

# This regular maven build will need to be replaced by the distribution
# specific maven build command, but this is ok for now:
# todo: eventually move to using mvn-build or mvn-rpmbuild so dependencies are
# not downloaded.
# Don't do the tests since those are already covered by the normal merge and
# verify process and this build does not need to verify them.
# maven.compile.fork is used to reduce the build time.
#export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=256m" && \
#  mvn clean install -Dmaven.test.skip=true -DskipIT -Dmaven.compile.fork=true
export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=256m" && mvn clean install -Dmaven.test.skip=true



%install
rm -rf %{buildroot}
cd odcs; make DESTDIR=%{buildroot} install; cd ..
cd odgw; make DESTDIR=%{buildroot} install; cd ..
cd ovs-agent; make DESTDIR=%{buildroot} install; cd ..

# Extract the contents of the distribution to a temporary directory so that we
# can take things from there and move them to the correct locations:
# todo: Need spec and pom file versions to be consistent so we don't have to
# hardcode the version here.
#mkdir -p tmp
#unzip -o -d tmp distribution/opendaylight/target/distribution.opendove-1.0.0-SNAPSHOT-osgipackage.zip

# Create the directories:
mkdir -p %{buildroot}%{resources_dir}/plugins

# Only install the extra jars needed by ovsdb.
# opendaylight jars will be moved to the plugins dir and external jars will be
# symlinked to the opendaylight dependencies directory.
for src in $( ls %{_builddir}/%{buildsubdir}/odmc/target/*.jar);
do
    tgt=org.opendaylight.opendove.$(basename ${src})
#    if [ ! -f %{_builddir}/%{buildsubdir}/distribution/opendaylight/target/generated-resources/opendaylight/plugins/${tgt} ]; then
#        if [ "${tgt}" != "${tgt/org.opendaylight/}" ]; then
            mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
#        else
#            ln -s %{deps_dir}/${tgt} %{buildroot}%{resources_dir}/plugins/${tgt}
#        fi
#    fi
done

for src in $( ls %{_builddir}/%{buildsubdir}/odmc/implementation/target/*.jar);
do
    tgt=org.opendaylight.opendove.$(basename ${src})
            mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
done

for src in $( ls %{_builddir}/%{buildsubdir}/odmc/rest/target/*.jar);
do
    tgt=org.opendaylight.opendove.$(basename ${src})
            mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
done

for src in $( ls %{_builddir}/%{buildsubdir}/odmc/rest/northbound/target/*.jar);
do
    tgt=org.opendaylight.opendove.$(basename ${src})
            mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
done

for src in $( ls %{_builddir}/%{buildsubdir}/odmc/rest/southbound/target/*.jar);
do
    tgt=org.opendaylight.opendove.$(basename ${src})
            mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
done

# Fix the permissions as they come with all the permissions (mode 777)
# from the .zip file:
find %{buildroot}%{resources_dir} -type d -exec chmod 755 {} \;
find %{buildroot}%{resources_dir} -type f -exec chmod 644 {} \;

# Remove the temporary directory:
#rm -rf tmp


%clean
%if "%{noclean}" == "1"
    exit 0
%endif


%files odcs

/opt/opendove/odcs/*

%files odgw

/opt/opendove/odgw/*

%files ovs-agent

/opt/opendove/ovs-agent/*

%files odmc

%{resources_dir}

%endif

%changelog
* Sat Feb 08 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.3.0
- Change libevent2_devel to libevent_devel for Fedora and RHEL.

* Thu Jan 23 2014 Anees Shaikh <aasdevaddr@gmail.com> - 0.1.0-0.2.0
- Added subpackages for all Open DOVE components

* Tue Jan 07 2014 Hsin-Yi Shen <hshen@redhat.com> - 0.1.0-0.1.0
- Initial package.
