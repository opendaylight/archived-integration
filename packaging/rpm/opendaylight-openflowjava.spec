# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight-openflowjava
Version: 0.1.0
Release: 0.1.0%{?dist}
Summary: OpenDaylight Openflow Java
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org

# todo: Temporary method for generating tarball
# git clone https://git.opendaylight.org/gerrit/p/openflowjava.git
# cd openflowjava
# git archive --prefix=opendaylight-openflowjava-0.1.0/ HEAD | xz > opendaylight-openflowjava-0.1.0.tar.xz
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
OpenDaylight Openflow Java


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
mkdir -p %{buildroot}%{resources_dir}/plugins

# Only install the extra jars needed by openflowjava.
# opendaylight jars will be moved to the plugins dir and external jars will be
# symlinked to the opendaylight dependencies directory.

for src in $( ls %{_builddir}/%{buildsubdir}/simple-client/target/*.jar);
do
    if [ "${src}" == "${src/javadoc.jar/}" ]; then
        tgt=org.opendaylight.openflowjava.$(basename ${src})
        mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
    fi
done

for src in $( ls %{_builddir}/%{buildsubdir}/openflow-protocol-it/target/*.jar);
do
    if [ "${src}" == "${src/javadoc.jar/}" ]; then
        tgt=org.opendaylight.openflowjava.$(basename ${src})
        mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
    fi
done

for src in $( ls %{_builddir}/%{buildsubdir}/openflow-protocol-spi/target/*.jar);
do
    if [ "${src}" == "${src/javadoc.jar/}" ]; then
        tgt=org.opendaylight.openflowjava.$(basename ${src})
        mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
    fi
done

for src in $( ls %{_builddir}/%{buildsubdir}/openflow-protocol-api/target/*.jar);
do
    if [ "${src}" == "${src/javadoc.jar/}" ]; then
        if [ "${src}" == "${src/sources.jar/}" ]; then
            tgt=org.opendaylight.openflowjava.$(basename ${src})
            mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
        fi
    fi
done

for src in $( ls %{_builddir}/%{buildsubdir}/openflow-protocol-impl/target/*.jar);
do
    if [ "${src}" == "${src/javadoc.jar/}" ]; then
        tgt=org.opendaylight.openflowjava.$(basename ${src})
        mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
    fi
done

for src in $( ls %{_builddir}/%{buildsubdir}/third-party/openflowj_netty/target/*.jar);
do
    if [ "${src}" == "${src/javadoc.jar/}" ]; then
        tgt=$(basename ${src})
        mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
    fi
done

for src in $( ls %{_builddir}/%{buildsubdir}/third-party/openflow-codec/target/*.jar);
do
    if [ "${src}" == "${src/javadoc.jar/}" ]; then
        tgt=$(basename ${src})
        mv ${src} %{buildroot}%{resources_dir}/plugins/${tgt}
    fi
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


%files

%{resources_dir}


%endif

%changelog
* Tue Jan 07 2014 Hsin-Yi Shen <hshen@redhat.com> - 0.1.0-0.1.0
- Initial package.
