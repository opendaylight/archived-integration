# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight-yangtools
Version: 0.1.0
Release: 0.1.0%{?dist}
Summary: OpenDaylight yangtools
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org

# todo: Temporary method for generating tarball
# git clone https://git.opendaylight.org/gerrit/p/yangtools.git
# cd yangtools
# git archive --prefix=opendaylight-yangtools-0.1.0/ HEAD | xz > opendaylight-yangtools-0.1.0.tar.xz
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
YANG Tools is a infrastructure project aiming to develop necessary
tooling and libraries providing support of NETCONF and YANG for Java
(JVM-language based) projects and applications, such as Model Driven
SAL for Controller (which uses YANG as it's modeling language) and
Netconf / OFConfig plugins.


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
    src=$(find . -name "*${artifact}" -a ! -name "*javadoc.jar" -a ! -name "*sources.jar")
    if [ -f "${src}" ]; then
        tgt=$(basename ${src})
        install -m 644 ${src} %{buildroot}%{resources_dir}/plugins/org.opendaylight.yangtools.${tgt}
    fi
done <<'.'
binding-generator-api-*.jar
binding-generator-impl-*.jar
binding-generator-spi-*.jar
binding-generator-util-*.jar
binding-model-api-*.jar
binding-type-provider-*.jar
concepts-*.jar
yang-binding-*.jar
yang-common-*.jar
yang-data-api-*.jar
yang-data-impl-*.jar
yang-data-util-*.jar
yang-model-api-*.jar
yang-model-util-*.jar
yang-parser-api-*.jar
yang-parser-impl-*.jar
.

# These next two loops have chairs that need a model prefix.
# But first take care of these topology jars. Notice there is another topology jar
# in the loop after this one, but its pattern matches all the topology jars and
# causes the -f to fail so break the loops apart. Some master regex god can
# probably combine the loops with magic.
while read base artifact; do
    src=$(find . -name "*${artifact}" -a ! -name "*javadoc.jar" -a ! -name "*sources.jar")
    if [ -f "${src}" ]; then
        tgt=$(basename ${src})
        install -m 644 ${src} %{buildroot}%{resources_dir}/plugins/org.opendaylight.yangtools.model.${tgt}
        rm -f ${src}
    fi
done <<'.'
model ietf-topology-isis-*.jar
model ietf-topology-l3-unicast-igp-*.jar
model ietf-topology-ospf-*.jar
.

while read base artifact; do
    src=$(find . -name "*${artifact}" -a ! -name "*javadoc.jar" -a ! -name "*sources.jar")
    if [ -f "${src}" ]; then
        tgt=$(basename ${src})
        install -m 644 ${src} %{buildroot}%{resources_dir}/plugins/org.opendaylight.yangtools.model.${tgt}
    fi
done <<'.'
model ietf-inet-types-*.jar
model ietf-ted-*.jar
model ietf-topology-*.jar
model ietf-yang-types-*.jar
model opendaylight-l2-types-*.jar
model yang-ext-*.jar
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
