# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight-bgpcep
Version: 0.1.0
Release: 0.2.0%{?dist}
Summary: OpenDaylight bgpcep
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org

# todo: Temporary method for generating tarball
# git clone https://git.opendaylight.org/gerrit/p/bgpcep.git
# cd bgpcep
# git archive --prefix=opendaylight-bgpcep-0.1.0/ HEAD | xz > opendaylight-bgpcep-0.1.0.tar.xz
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
BGP/LS and PCEP project is an effort to bring two south-bound plugins
into the controller: one for supporting BGP Linkstate Distribution as
a source of L3 topology information, the other one to add support for
Path Computation Element Protocol as a way to instantiate paths into
the underlying network.


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
        install -m 644 ${src} %{buildroot}%{resources_dir}/plugins/org.opendaylight.bgpcep.${tgt}
    fi
done <<'.'
bgp-concepts-*.jar
bgp-controller-config-*.jar
bgp-linkstate-*.jar
bgp-linkstate-config-*.jar
bgp-parser-api-*.jar
bgp-parser-impl-*.jar
bgp-parser-spi-*.jar
bgp-parser-spi-config-*.jar
bgp-rib-api-*.jar
bgp-rib-api-config-*.jar
bgp-rib-impl-*.jar
bgp-rib-impl-config-*.jar
bgp-rib-spi-*.jar
bgp-rib-spi-config-*.jar
bgp-topology-provider-*.jar
bgp-topology-provider-config-*.jar
bgp-update-api-config-*.jar
bgp-util-*.jar
concepts-*.jar
pcep-api-*.jar
pcep-api-config-*.jar
pcep-controller-config-*.jar
pcep-ietf-stateful02-*.jar
pcep-ietf-stateful07-*.jar
pcep-impl-*.jar
pcep-impl-config-*.jar
pcep-spi-*.jar
pcep-spi-config-*.jar
pcep-testtool-*.jar
pcep-topology-api-*.jar
pcep-topology-provider-*.jar
pcep-topology-provider-config-*.jar
pcep-topology-spi-*.jar
pcep-tunnel-api-*.jar
pcep-tunnel-provider-*.jar
pcep-tunnel-provider-config-*.jar
programming-api-*.jar
programming-controller-config-*.jar
programming-impl-*.jar
programming-impl-config-*.jar
programming-spi-*.jar
programming-spi-config-*.jar
programming-topology-api-*.jar
programming-tunnel-api-*.jar
rsvp-api-*.jar
tcpmd5-api-*.jar
tcpmd5-api-cfg-*.jar
tcpmd5-jni-*.jar
tcpmd5-jni-cfg-*.jar
tcpmd5-netty-*.jar
tcpmd5-netty-cfg-*.jar
tcpmd5-nio-*.jar
topology-api-*.jar
topology-api-config-*.jar
topology-tunnel-api-*.jar
util-*.jar
.

install -d -m 755 %{buildroot}%{resources_dir}/configuration/initial

while read config; do
    src=$(find . -not -path "*/src/*" -name "${config}")
    if [ -f "${src}" ]; then
        tgt=$(basename ${src})
        install -m 644 ${src} %{buildroot}%{resources_dir}/configuration/initial/${tgt}
    fi
done <<'.'
30-programming.xml
31-bgp.xml
32-pcep.xml
39-pcep-provider.xml
41-bgp-example.xml
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
* Tue May 13 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.2.0
- Add additional artifacts and xml files.

* Sat Feb 08 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.1.0
- Initial package.
