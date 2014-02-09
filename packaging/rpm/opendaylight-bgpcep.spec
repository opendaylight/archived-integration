# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight-bgpcep
Version: 0.1.0
Release: 0.1.0%{?dist}
Summary: OpenDaylight bgpcep
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org

# todo: Temporary method for generating tarball
# git clone https://git.opendaylight.org/gerrit/p/bgpcep.git
# cd bgpcep
# git archive --prefix=opendaylight-bgpcep-0.1.0/ HEAD | xz > opendaylight-bgpcep-0.1.0.tar.xz
# git clone https://git.opendaylight.org/gerrit/p/yangtools.git
# cd bgpcep
# git archive --prefix=opendaylight-yangtools-0.1.0/ HEAD | xz > opendaylight-yangtools-0.1.0.tar.xz
Source0: %{name}-%{version}.tar.xz
Source1: %{name}-yangtools.tar.xz

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
%setup -q -D -T -a 1


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
bgp-concepts-0.3.0.jar
bgp-controller-config-0.3.0.jar
bgp-linkstate-0.3.0.jar
bgp-linkstate-config-0.3.0.jar
bgp-parser-api-0.3.0.jar
bgp-parser-impl-0.3.0.jar
bgp-parser-spi-0.3.0.jar
bgp-parser-spi-config-0.3.0.jar
bgp-rib-api-0.3.0.jar
bgp-rib-api-config-0.3.0.jar
bgp-rib-impl-0.3.0.jar
bgp-rib-impl-config-0.3.0.jar
bgp-rib-spi-0.3.0.jar
bgp-rib-spi-config-0.3.0.jar
bgp-topology-provider-0.3.0.jar
bgp-topology-provider-config-0.3.0.jar
bgp-update-api-config-0.3.0.jar
bgp-util-0.3.0.jar
concepts-0.3.0.jar
pcep-api-0.3.0.jar
pcep-api-config-0.3.0.jar
pcep-controller-config-0.3.0.jar
pcep-ietf-stateful02-0.3.0.jar
pcep-ietf-stateful07-0.3.0.jar
pcep-impl-0.3.0.jar
pcep-impl-config-0.3.0.jar
pcep-spi-0.3.0.jar
pcep-spi-config-0.3.0.jar
pcep-testtool-0.3.0.jar
pcep-topology-api-0.3.0.jar
pcep-topology-provider-0.3.0.jar
pcep-topology-provider-config-0.3.0.jar
pcep-topology-spi-0.3.0.jar
pcep-tunnel-api-0.3.0.jar
pcep-tunnel-provider-0.3.0.jar
pcep-tunnel-provider-config-0.3.0.jar
programming-api-0.3.0.jar
programming-controller-config-0.3.0.jar
programming-impl-0.3.0.jar
programming-impl-config-0.3.0.jar
programming-spi-0.3.0.jar
programming-spi-config-0.3.0.jar
programming-topology-api-0.3.0.jar
programming-tunnel-api-0.3.0.jar
rsvp-api-0.3.0.jar
topology-api-0.3.0.jar
topology-api-config-0.3.0.jar
topology-tunnel-api-0.3.0.jar
util-0.3.0.jar
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
