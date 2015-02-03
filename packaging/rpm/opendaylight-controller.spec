# Spec file only supports RHEL and Fedora now
%if 0%{?rhel} || 0%{?fedora}

Name: opendaylight-controller
Version: 0.1.0
Release: 0.12.0%{?dist}
Summary: OpenDaylight SDN Controller
Group: Applications/Communications
License: EPL
URL: http://www.opendaylight.org

# todo: Temporary method for generating tarball
# git clone https://git.opendaylight.org/gerrit/p/controller.git
# cd controller
# git archive --prefix=opendaylight-controller-0.1.0/ HEAD | xz > opendaylight-controller-0.1.0.tar.xz
# git clone https://git.opendaylight.org/gerrit/p/integration.git
# cd integration
# git archive --prefix=opendaylight-integration-0.1.0/HEAD | xz > opendaylight-integration-0.1.0.tar.xz
Source0: %{name}-%{version}.tar.xz
Source1: opendaylight-integration-%{version}.tar.xz
Patch0: opendaylight-integration-fix-paths.patch

BuildArch: noarch

BuildRequires: java-devel
BuildRequires: maven
Requires: java >= 1:1.7.0
%if 0%{?fedora}
BuildRequires: systemd
%else
BuildRequires: sysvinit-tools
%endif


# todo: Need to create proper packages for all the dependencies.
# Here you should have at least dependencies for the packages containing .jar
# files that you want to create symlinks to. For now all the jars in a
# dependencies package.
#Requires: slf4j

#Requires: %{name}-dependencies
#Requires: opendaylight-openflowjava
#Requires: opendaylight-openflowplugin

%if 0%{?fedora}
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd
%else
# use sysV for rhel
Requires(post): chkconfig
Requires(preun): chkconfig

# This is for /sbin/service
Requires(preun): initscripts
Requires(postun): initscripts
%endif


# This is the directory where all the application resources (scripts,
# libraries, etc) will be installed: /usr/share/opendaylight
%global resources_dir %{_datadir}/%{name}

# This is the directory where variable data used by the application should be
# created: /var/lib/opendaylight
%global data_dir %{_localstatedir}/lib/%{name}

# This is the directory where the application stores its configuration:
# /etc/opendaylight
%global configuration_dir %{_sysconfdir}/%{name}

# This is the directory that has all the JAVA dependencies.
%global deps_dir %{_javadir}/opendaylight-controller-dependencies

# This is the integration buildsubdir and packaging dirs:
#%global intbuildsubdir %{_builddir}/%{buildsubdir}/opendaylight-integration-%{version}
%global pkgdir opendaylight-integration-%{version}/packaging/rpm


%description
The OpenDaylight SDN Controller Platform provides the core services
and abstractions needed for building an SDN controller.


%prep

%setup -q
%setup -q -D -T -a 1
cd opendaylight-integration-%{version}
%patch0 -p1


# In more restrictive distributions we should also here remove from the source
# package any third party binaries, or replace them with those provided by the
# distribution, before performing the actual build.


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

# Extract the contents of the distribution to a temporary directory so that we
# can take things from there and move them to the correct locations:
mkdir -p tmp
unzip -o -d tmp opendaylight/distribution/opendaylight/target/distribution.opendaylight-osgipackage.zip

# Create the directories:
mkdir -p %{buildroot}%{configuration_dir}
mkdir -p %{buildroot}%{resources_dir}/configuration
mkdir -p %{buildroot}%{data_dir}/configuration

mv tmp/opendaylight/configuration/config.ini %{buildroot}%{configuration_dir}
sed -i -e 's/#\ ovsdb.of.version=1.3/ovsdb.of.version=1.3/' %{buildroot}%{configuration_dir}/config.ini
ln -s %{configuration_dir}/config.ini %{buildroot}%{data_dir}/configuration
mv tmp/opendaylight/configuration/* %{buildroot}%{resources_dir}/configuration
rmdir tmp/opendaylight/configuration
ln -s %{resources_dir}/configuration/initial %{buildroot}%{data_dir}/configuration
ln -s %{resources_dir}/configuration/context.xml %{buildroot}%{data_dir}/configuration
ln -s %{resources_dir}/configuration/logback.xml %{buildroot}%{data_dir}/configuration
ln -s %{resources_dir}/configuration/tomcat-server.xml %{buildroot}%{data_dir}/configuration
ln -s %{resources_dir}/configuration/tomcat-logging.properties %{buildroot}%{data_dir}/configuration
ln -s %{resources_dir}/configuration/RSA.pk %{buildroot}%{data_dir}/configuration

mv tmp/opendaylight/* %{buildroot}%{resources_dir}

ln -s %{resources_dir}/lib %{buildroot}%{data_dir}
ln -s %{resources_dir}/plugins %{buildroot}%{data_dir}

%if 0%{?fedora}
install -m 644 -D %{pkgdir}/%{name}.systemd %{buildroot}%{_unitdir}/%{name}.service
%else
install -m 644 -D %{pkgdir}/%{name}.sysv %{buildroot}%{_initddir}/%{name}
install -m 644 -D %{pkgdir}/%{name}.limits %{buildroot}%{_sysconfdir}/security/limits.d/%{name}
%endif
install -m 644 -D %{pkgdir}/%{name}.sysconfig %{buildroot}%{_sysconfdir}/sysconfig/%{name}

# Fix all the run.sh files to the right names.
install -m 755 -D %{buildroot}%{resources_dir}/run.sh %{buildroot}%{resources_dir}/run.internal.sh
install -m 755 -D opendaylight-integration-%{version}/distributions/base/src/assemble/resources/run.sh \
    %{buildroot}%{resources_dir}/run.base.sh
rm %{buildroot}%{resources_dir}/run.sh
install -m 755 -D opendaylight-integration-%{version}/distributions/virtualization/src/assemble/resources/run.sh \
    %{buildroot}%{resources_dir}/run.sh
install -m 755 -D opendaylight-integration-%{version}/packaging/rpm/run.odl.sh %{buildroot}%{resources_dir}/run.odl.sh

# Usually one wants to replace the .jar files of the dependencies by symlinks
# to the ones provided to the system. This assumes the dependencies have been
# installed as separate packages and listed in the Requires header.
cd %{buildroot}%{resources_dir}/lib
for src in $( ls -I "org.opendaylight.*" );
do
    rm -f ${src}
    #tgt=$(echo ${src} | sed -e "s/-[0-9].*/.jar/")
    #ln -s %{deps_dir}/${tgt} ${src}
    ln -s %{deps_dir}/${src} ${src}
done

cd %{buildroot}%{resources_dir}/plugins
# rm the yangtools since they are part of the yangtools.rpm, but keep the yangtools.thirdparty
mv org.opendaylight.yangtools.thirdparty.* /tmp
rm -f org.opendaylight.yangtools.*
mv /tmp/org.opendaylight.yangtools.thirdparty.* .
for src in $( ls -I "org.opendaylight.*" );
do
    rm -f ${src}
    #tgt=$(echo ${src} | sed -e "s/-[0-9].*/.jar/")
    #ln -s %{deps_dir}/${tgt} ${src}
    ln -s %{deps_dir}/${src} ${src}
done


# Fix the permissions as they come with all the permissions (mode 777)
# from the .zip file:
find %{buildroot}%{resources_dir} -type d -exec chmod 755 {} \;
find %{buildroot}%{resources_dir} -type f -exec chmod 644 {} \;
find %{buildroot}%{data_dir} -type d -exec chmod 755 {} \;
find %{buildroot}%{data_dir} -type f -exec chmod 755 {} \;
chmod 755 %{buildroot}%{resources_dir}/run.sh
chmod 755 %{buildroot}%{resources_dir}/run.base.sh
chmod 755 %{buildroot}%{resources_dir}/run.internal.sh
chmod 755 %{buildroot}%{resources_dir}/run.odl.sh
%if 0%{?rhel}
chmod 755 %{buildroot}%{_initddir}/%{name}
%endif

# Remove the temporary directory:
rm -rf tmp


%pre

# todo: register the opendaylight group:user.
# Create the group and user that will run the service before installing the
# package, as some of the files and directories will be owned by this user:
getent group opendaylight > /dev/null
if [ "$?" != 0 ]; then
    groupadd \
        -f \
        -r \
        opendaylight
fi

getent passwd opendaylight > /dev/null
if [ "$?" != 0 ]; then
    useradd \
        -r \
        -g opendaylight \
        -c "OpenDaylight SDN" \
        -s /sbin/nologin \
        -d %{data_dir} \
        opendaylight
fi

# Currently not enabling service on boot.
#%post
#%systemd_post %{name}.service

%preun
%if 0%{?fedora}
%systemd_preun %{name}.service
%else
if [ $1 -eq 0 ] ; then
    /sbin/service %{name} stop >/dev/null 2>&1
    /sbin/chkconfig --del %{name}
fi
%endif

%postun
%if 0%{?fedora}
%systemd_postun
%else
if [ "$1" -ge "1" ] ; then
    /sbin/service %{name} condrestart >/dev/null 2>&1 || :
fi
%endif

%clean
# This check is used for mock build so the build files are not deleted.
%if "%{noclean}" == "1"
    exit 0
%endif


%files

%{resources_dir}
%if 0%{?fedora}
%{_unitdir}/%{name}.service
%else
%{_initddir}/%{name}
%{_sysconfdir}/security/limits.d/%{name}
%endif

# Configuration files should marked as such, so that they aren't overwritten
# when updating the package:
%dir %{configuration_dir}
%config(noreplace) %{configuration_dir}/config.ini
%config(noreplace) %{_sysconfdir}/sysconfig/%{name}

# The data directory needs to be owned by the user that will run the service,
# as it will need to write inside:
%attr(-, opendaylight, opendaylight) %{data_dir}

# Documentation:
%doc LICENSE
%doc NOTICE
%doc README.OPENDAYLIGHT

%endif

%changelog
* Mon Feb 10 2014 Miroslav Miklus <mmiklus@cisco.com> - 0.1.0-0.12.0
- Updates to include higher resource limits.

* Sat Feb 08 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.11.0
- Remove yangtools artifacts.

* Sat Feb 01 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.10.0
- Changed package name to opendaylight.
- Removed openflowjava and openflowplugin Requires.

* Wed Jan 22 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.9.0
- Updates to support editions.

* Wed Jan 22 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.8.0
- Fix changelog day error.

* Fri Jan 10 2014 Hsin-Yi Shen <hshen@redhat.com> - 0.1.0-0.7.0
- Updates to include openflowjava and openflowplugin.

* Fri Jan 10 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.6.0
- Updates to include new configuration files.

* Thu Jan 09 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.5.0
- Updates for OF1.3 support.

* Thu Jan 02 2014 Sam Hague <shague@redhat.com> - 0.1.0-0.4.0
- Updates to include building distributions.

* Mon Dec 23 2013 Hsin-Yi Shen <hshen@redhat.com> - 0.1.0-0.3.0
- Updates to support building rpm for both RHEL and fedora.

* Fri Nov 22 2013 Sam Hague <shague@redhat.com> - 0.1.0-0.2.0
- Updates to support building rpm with jenkins.

* Tue Nov 12 2013 Sam Hague <shague@redhat.com> - 0.1.0-0.1.20131007git20dcbd1
- Modify the source tarball instructions and name.

* Wed Nov 06 2013 Sam Hague <shague@redhat.com> - 0.1.0-0.1.20131007git2f02ee4
- Add systemd support to install the service.
- Simplify the file permission modification logic.
- Modify the mvn command to not build tests.

* Fri Nov 01 2013 Sam Hague <shague@redhat.com> - 0.1.0-0.1.20131007git31c8f18
- Modify to include opendaylight-controller-dependencies.
- Do not delete the files in var

* Mon Oct 07 2013 Sam Hague <shague@redhat.com> - 0.1.0-0.1.20131007gitd684dd4
- Initial Fedora package.
