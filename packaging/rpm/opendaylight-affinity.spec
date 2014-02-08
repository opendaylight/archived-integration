# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight-affinity
Version: 0.1.0
Release: 0.1.0%{?dist}
Summary: OpenDaylight affinity
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org

# todo: Temporary method for generating tarball
# git clone https://git.opendaylight.org/gerrit/p/affinity.git
# cd affinity
# git archive --prefix=opendaylight-affinity-0.1.0/ HEAD | xz > opendaylight-affinity-0.1.0.tar.xz
Source0: %{name}-%{version}.tar.xz

BuildArch: noarch

BuildRequires: java-devel
BuildRequires: maven
Requires: java >= 1:1.7.0

# This is the directory where all the application resources (scripts,
# libraries, etc) will be installed: /usr/share/opendaylight
%global resources_dir %{_datadir}/opendaylight-controller

# This is the directory that has all the JAVA dependencies.
%global deps_dir %{_javadir}/opendaylight-controller-dependencies


%description
OpenDaylight affinity is a southbound plugin that can control
off-the-shelf commodity Ethernet switches using SNMP.


%prep

%setup -q


%build

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

# Create the directories:
install -d -m 755 %{buildroot}%{resources_dir}/plugins

while read artifact; do
    src=$(find . -name "*${artifact}")
    if [ -f "${src}" ]; then
        tgt=$(basename ${src})
        install -m 644 ${src} %{buildroot}%{resources_dir}/plugins/org.opendaylight.affinity.${tgt}
    fi
done <<'.'
affinity-*.jar
affinity.implementation-*.jar
affinity.northbound-*.jar
analytics-*.jar
analytics.implementation-*.jar
analytics.northbound-*.jar
flatl2-*.jar
l2agent-*.jar
.

# Remove the temporary directory:
rm -rf tmp


%clean
%if "%{noclean}" == "1"
    exit 0
%endif


%files

%{resources_dir}


%endif

%changelog
* Sat Feb 08 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.1.0
- Initial package.
