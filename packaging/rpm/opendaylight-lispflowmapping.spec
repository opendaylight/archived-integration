# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight-lispflowmapping
Version: 0.1.0
Release: 0.2.0%{?dist}
Summary: OpenDaylight LispFlowMapping
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org

# todo: Temporary method for generating tarball
# git clone https://git.opendaylight.org/gerrit/p/lispflowmapping.git
# cd lispflowmapping
# git archive --prefix=opendaylight-lispflowmapping-1.0.0/ HEAD | xz > opendaylight-lispflowmapping-1.0.0.tar.xz
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
OpenDaylight LispFlowMapping


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
        install -m 644 ${src} %{buildroot}%{resources_dir}/plugins/org.opendaylight.lispflowmapping.${tgt}
    fi
done <<'.'
mappingservice.api-*.jar
mappingservice.config-*.jar
mappingservice.implementation-*.jar
mappingservice.northbound-*.jar
mappingservice.southbound-*.jar
mappingservice.yangmodel-*.jar
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
* Sat Feb 08 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.2.0
- Include only lispflowmapping jars.

* Wed Jan 22 2014 David Goldberg <david.goldberg@contextream.com> - 0.1.0-0.1.0
- Initial package.
