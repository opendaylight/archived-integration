#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>

# shague todo:
# - Add -r option for mock to choose the distribution
# - add option to pass in spec file name, maybe use spec.in template
# - add option to pass in version and release

#set -vx

buildtype="snapshot"
buildroot=""
buildtag=""
cleanroot=0
cleantmp=0
pushrpms=0
getsource="buildroot"
branch=""
depth=0
version=""
edversion=""
specrelease="1"
releasetag=0
versiontype="spec"
repourl=""
repouser=""
repopw=""
dist="fedora-19-x86_64"
pkg_dist_suffix="fc19"
mock_cmd="/usr/bin/mock"
vers_controller=""
vers_ovsdb=""
suff_controller=""
suff_ovsdb=""
mockdebug=""
mockinit=0
tmpbuild=""
mockmvn=""
timesuffix=""
shortcircuits=0
shortcircuite=0
listprojects=0

# Maven is not installed at the system wide level but at the Jenkins level
# We need to map our Maven call to the Jenkins installed version
mvn_cmd="$JENKINS_HOME/tools/hudson.tasks.Maven_MavenInstallation/Maven_3.0.4/bin/mvn"

# Define our push repositories here. We do it in code since we can't
# use a POM file for the RPM pushes (we're doing "one-off" file pushes)
#
# Repositories will be of the form baseRepositoryId-$dist{-testing}
# -testing if it's a snapshot build (not using -snapshot as the name as
# -testing is the more common testing repo suffix for yum)
baseURL="http://nexus.opendaylight.org/content/repositories/opendaylight-yum-"
baseRepositoryId="opendaylight-yum-"

readonly RCSUCCESS=0
readonly RCERROR=64
readonly RCPARMSERROR=65
readonly RCRPMBUILDERROR=66
readonly RCRMOCKERROR=67
readonly RCGITERROR=68

readonly LOGERROR=2
readonly LOGINFO=5
readonly LOGVERBOSE=7
loglevel=$LOGVERBOSE


function log {
    local level=$1; shift;

    if [ $level -le $loglevel ]; then
        echo "buildrpm: $@"
    fi
}

function usage {
    local rc=$1
    local outstr=$2

    if [ "$outstr" != "" ]; then
        echo "$outstr"
        echo
    fi

    echo "Usage: `basename $0` [OPTION...]"
    echo
    echo "Build options:"
    echo "  --buildtype TYPE       build type, either snapshot or release, default snapshot"
    echo "  --buildroot DIRECTORY  build root path. The path must exist."
    echo "  --buildtag             tag the tmpbuild directory, i.e. Jenkins build number"
    echo "  --cleanroot            clean buildroot directory before building"
    echo "  --cleantmp             clean tmpbuild directory before building"
    echo "  --dist DIST            distribution, default fedora-19-x86_64"
    echo "  --distsuffix SUFFIX    package distribution suffix, default f19"
    echo "  --getsource METHOD     method for getting source clone|snapshot|buildroot, default buildroot"
    echo
    echo "Tag options:"
    echo "  --releasetag           use the latest release tagged repos"
    echo "  --specrelease          version used for spec Release:, default 1"
    echo "  --versiontype TYPE     where to find version, user|pom|spec, default spec"
    echo "  --version VERSION      version value to use in build output. Required for --version_type user option."
    echo "  --edversion VERSION    version value to use in build output for edition rpms"
    echo "  --branch BRANCH        branch to use for source"
    echo
    echo "Repo sync options:"
    echo "  --repourl REPOURL      url of the repo, include http://"
    echo "  --repouser REPOUSER    user for repo"
    echo "  --repopw REPOPW        password for repo"
    echo
    echo "Deployment options:"
    echo "  --pushrpms             push the built rpms to a maven repository"
    echo "  --mvn_cmd              fully qualified path to where the mvn command"
    echo "                         (defaults to Jenkins installation of Maven 3.0.4)"
    echo "  --baseURL              base deployment URL. \$dist will be added to the end of this"
    echo "                         If this is a snapshot build then -testing be added at the end"
    echo "  --baseRepositoryId     base repository name. \$dist will be added to the end of this"
    echo "                         If this is a snapshot build then -testing be added at the end"
    echo
    echo "Mock options:"
    echo "  --mockinit             Run mock init"
    echo "  --mockmvn              replace the maven command used within mock"
    echo
    echo "Help options:"
    echo "  -?, -h, --help  Display this help and exit"
    echo "  --debug         Enable bash debugging output"
    echo "  --mockdebug     Enable mock debugging output"
    echo
    echo "Extras:"
    echo "  --shortcircuits INDEX  Start build with project index"
    echo "  --shortcircuite INDEX  End build with project index"
    echo "  --listprojects         List the projects and indexes"
    echo "  --timesuffix TIME      Set the time suffix to use for build output"

    exit $rc
}

readonly PJ_FIRST=0
readonly PJ_INTEGRATION=0
readonly PJ_CONTROLLER=1
readonly PJ_OVSDB=2
readonly PJ_OPENFLOWJAVA=3
readonly PJ_OPENFLOWPLUGIN=4
readonly PJ_DEPENDENCIES=5
readonly PJ_OPENDAYLIGHT=6
readonly PJ_LISPFLOWMAPPING=7
readonly PJ_SNMP4SDN=8
readonly PJ_AFFINITY=9
readonly PJ_YANGTOOLS=10
readonly PJ_BGPCEP=11
readonly PJ_OPENDOVE=12
readonly PJ_LAST=$PJ_BGPCEP
#readonly PJ_LAST=$PJ_OPENDOVE

projects[$PJ_INTEGRATION]="integration"
projects[$PJ_CONTROLLER]="controller"
projects[$PJ_OVSDB]="ovsdb"
projects[$PJ_OPENFLOWJAVA]="openflowjava"
projects[$PJ_OPENFLOWPLUGIN]="openflowplugin"
projects[$PJ_DEPENDENCIES]="controller-dependencies"
projects[$PJ_OPENDAYLIGHT]="opendaylight"
projects[$PJ_LISPFLOWMAPPING]="lispflowmapping"
projects[$PJ_SNMP4SDN]="snmp4sdn"
projects[$PJ_AFFINITY]="affinity"
projects[$PJ_YANGTOOLS]="yangtools"
projects[$PJ_BGPCEP]="bgpcep"
projects[$PJ_OPENDOVE]="opendove"

versions[$PJ_INTEGRATION]=""
versions[$PJ_CONTROLLER]=""
versions[$PJ_OVSDB]=""
versions[$PJ_OPENFLOWJAVA]=""
versions[$PJ_OPENFLOWPLUGIN]=""
versions[$PJ_DEPENDENCIES]=""
versions[$PJ_OPENDAYLIGHT]=""
versions[$PJ_LISPFLOWMAPPING]=""
versions[$PJ_SNMP4SDN]=""
versions[$PJ_AFFINITY]=""
versions[$PJ_YANGTOOLS]=""
versions[$PJ_BGPCEP]=""
versions[$PJ_OPENDOVE]=""

suffix[$PJ_INTEGRATION]=""
suffix[$PJ_CONTROLLER]=""
suffix[$PJ_OVSDB]=""
suffix[$PJ_OPENFLOWJAVA]=""
suffix[$PJ_OPENFLOWPLUGIN]=""
suffix[$PJ_DEPENDENCIES]=""
suffix[$PJ_OPENDAYLIGHT]=""
suffix[$PJ_LISPFLOWMAPPING]=""
suffix[$PJ_SNMP4SDN]=""
suffix[$PJ_AFFINITY]=""
suffix[$PJ_YANGTOOLS]=""
suffix[$PJ_BGPCEP]=""
suffix[$PJ_OPENDOVE]=""

gitprojects="$PJ_INTEGRATION $PJ_CONTROLLER $PJ_OVSDB $PJ_OPENFLOWJAVA $PJ_OPENFLOWPLUGIN $PJ_LISPFLOWMAPPING $PJ_SNMP4SDN $PJ_AFFINITY $PJ_YANGTOOLS $PJ_BGPCEP $PJ_OPENDOVE"

# Clone the projects.
function clone_source {
    local depth=$1
    for i in $gitprojects; do
        if [ depth -eq 0 ]; then
            # We only care about a shallow clone (no need to grab the entire project)
            log $LOGINFO "Shallow cloning ${projects[$i]} to $buildroot/${projects[$i]}"
            git clone --depth 0 https://git.opendaylight.org/gerrit/p/${projects[$i]}.git $buildroot/${projects[$i]}
        else
            log $LOGINFO "Full cloning ${projects[$i]} to $buildroot/${projects[$i]}"
            git clone https://git.opendaylight.org/gerrit/p/${projects[$i]}.git $buildroot/${projects[$i]}
        fi
    done
}

# Copy the projects from snapshots.
# shague: Fill in with the nexus info.
# Make mk_snapshot_archives that just sets up the version strings.
function snapshot_source {
    log $LOGINFO "$FUNCNAME: Not implemented yet."
}

# Checkout the latest release-tagged branch.
# TODO: does this work for branches or for multiple releases?
function checkout_release_tag {
    local tag=""

    for i in $gitprojects; do
        # Leave integration as is. The release version has a bug. Assume the latest in the
        # repo is good.
        if [ "${projects[$i]}" == "${projects[$PJ_INTEGRATION]}" ]; then
            continue
        fi
        cd $buildroot/${projects[$i]}
        # Find the last release tag for the project.
        # We assume that the first git log matching "[maven-release-plugin] prepare release"
        # is where the tag was created.
        tag=$(git log | grep -m 1 "\[maven-release-plugin\] prepare release" | awk '{print $4}')
        if [ "$tag" != "" ]; then
            git checkout --quiet "$tag"
        else
            log $LOGERROR "${projects[i]} is missing release tag"
            exit $RCGITERROR
        fi
    done
}

# Checkout the requested branch.
function checkout_branch {
    local branch=$1

    for i in $gitprojects; do
        cd $buildroot/${projects[$i]}
        git checkout $branch
    done
}

function set_versions {
    local timesuffix=$1
    local versiontype=$2
    local version=$3
    local buildtype=$4

    for i in $gitprojects; do
        case "$versiontype" in
        "user")
            # User set the version.
            versions[$i]=$version
            ;;

        "spec")
            # rpm query the spec file to get the Version.
            cd $buildroot/${projects[$PJ_INTEGRATION]}/packaging/rpm
            if [ ${projects[$i]} == ${projects[$PJ_INTEGRATION]} ]; then
                # use opendaylight spec since there is no integration spec
                versions[$i]="$( rpm -q --queryformat="%{version}\n" --specfile opendaylight.spec | head -n 1 | awk '{print $1}')"
            else
                versions[$i]="$( rpm -q --queryformat="%{version}\n" --specfile opendaylight-${projects[$i]}.spec | head -n 1 | awk '{print $1}')"
            fi
            ;;

        "pom")
            # Find the first version tag in the pom.xml file - this should be the correct version.
            # Then strip the version tags and end up with the version string.
            versions[$i]=$(grep -m 1 "<version>" $buildroot/${projects[$i]}/pom.xml | sed -n -e '/<version>/s/.*<version>//p' | sed -n -e 's/<\/version>//p')
            ;;
        esac

        if [ "$buildtype" == "snapshot" ]; then
            cd $buildroot/${projects[$i]}
            suffix[$i]="snap.$timesuffix.git.$(git log -1 --pretty=format:%h)"
            versions[$i]="${versions[$i]}.${suffix[$i]}"
        else
            suffix[$i]=""
        fi

        # Remove any -'s from the version. rpmbuild does not like them.
        version=${versions[$i]}
        versions[$i]=${version//-/.}
    done

    # The dependencies and opendaylight projects do not have a repo so set them to the
    # controller and integration versions.

    # Dependencies follows the controller.
    suffix[$PJ_DEPENDENCIES]=${suffix[$PJ_CONTROLLER]}
    versions[$PJ_DEPENDENCIES]=${versions[$PJ_CONTROLLER]}

    # Opendaylight follows integration since they are the editions, unless the
    # user wants to set the value explicitly.
    if [ "$edversion" == "" ]; then
        suffix[$PJ_OPENDAYLIGHT]=${suffix[$PJ_INTEGRATION]}
        versions[$PJ_OPENDAYLIGHT]=${versions[$PJ_INTEGRATION]}
    else
        suffix[$PJ_OPENDAYLIGHT]=""
        versions[$PJ_OPENDAYLIGHT]=$edversion
    fi
}

# Archive the projects to create the SOURCES for rpmbuild:
# - xz the source for later use by rpmbuild.
# - get the version and git hashes to produce a versions and suffix for each project.
# - copy the archives to the SOURCES dir
# shague: need another archive method for snapshot getsource builds since
# the source did not come from a git repo.
# versionmajor=0.1.0.snap.20140201.191633.git.7c5788d
# versionsnapsuffix=snap.20140201.191633.git.7c5788d

function mk_git_archives {
#    local timesuffix=$1

    for i in $gitprojects; do
        log $LOGINFO "Building archive: $tmpbuild/opendaylight-${projects[$i]}-${versions[$i]}.tar.xz"
        cd $buildroot/${projects[$i]}
        git archive --prefix=opendaylight-${projects[$i]}-${versions[$i]}/ HEAD | \
            xz > $tmpbuild/opendaylight-${projects[$i]}-${versions[$i]}.tar.xz
    done

    # Don't forget any patches.
    cp $buildroot/${projects[$PJ_INTEGRATION]}/packaging/rpm/opendaylight-integration-fix-paths.patch $tmpbuild
}

# Pushes rpms to the specified Nexus repository
# This only happens if pushrpms is true
function push_rpms {
    if [ $pushrpms = 1 ]; then
        allrpms=`find $tmpbuild/repo -iname '*.rpm'`
        echo
        log $LOGINFO "RPMS found"
        for i in $allrpms; do
            log $LOGINFO $i
        done

        log $LOGINFO ":::::"
        log $LOGINFO "::::: pushing RPMs"
        log $LOGINFO ":::::"
        for i in $allrpms; do
            rpmname=`rpm -qp --queryformat="%{name}" $i`
            rpmversion=`rpm -qp --queryformat="%{version}" $i`
            distro=`echo $dist | tr - .`

            if [ `echo $i | grep 'src.rpm'` ]; then
                rpmrelease=`rpm -qp --queryformat="%{release}.src" $i`
                groupId="srpm"
            else
                rpmrelease=`rpm -qp --queryformat="%{release}.%{arch}" $i`
                groupId="rpm"
            fi


            if [ "$buildtype" == "snapshot" ]; then
                repositoryId="${baseRepositoryId}${dist}-testing"
                pushURL="${baseURL}${dist}-testing"
            else
                repositoryId="${baseRepositoryId}${dist}"
                pushURL="${baseURL}${dist}"
            fi

            # Note version is the full version+release+{arch|src}
            # if it is not configured this way on pushes then a download
            # of the artifact will result in just the name-version.rpm
            # instead of name-version-release.{arch|src}.rpm
            $mvn_cmd org.apache.maven.plugins:maven-deploy-plugin:2.8.1:deploy-file \
                -Dfile=$i -DrepositoryId=$repositoryId \
                -Durl=$pushURL -DgroupId=$groupId \
                -Dversion=$rpmversion-$rpmrelease -DartifactId=$rpmname \
                -Dtype=rpm
        done
    fi
}

function show_vars {
     cat << EOF
Building controller using:
distribution:   $dist
suffix:         $pkg_dist_suffix
buildtype:      $buildtype
versiontype:    $versiontype
version:        $version
edversion:      $edversion
branch:         $branch
specrelease:    $specrelease
releasetag:     $releasetag
getsource:      $getsource
buildroot:      $buildroot
buildtag:       $buildtag
tmpbuild:       $tmpbuild
mockmvn:        $mockmvn
mockinit:       $mockinit
shortcircuits:  $shortcircuits
shortcircuite:  $shortcircuite
time:           $timesuffix
EOF
}

# Build a single project.
function build_project {
    local project="$1"
    local versionmajor="$2"
    local versionsnapsuffix="$3"
    local projectspec=""

    if [ "$project" == "opendaylight" ]; then
        projectspec="opendaylight"
    else
        projectspec="opendaylight-$project"
    fi

    log $LOGINFO ":::::"
    log $LOGINFO "::::: building $projectspec.rpm"
    log $LOGINFO ":::::"

    cp -f $buildroot/${projects[$PJ_INTEGRATION]}/packaging/rpm/$projectspec.spec $tmpbuild

    cd $tmpbuild
    # Rewrite the Version and Release values in the spec files.
    sed -r -i -e '/^Version:./c\Version: '"$versionmajor"  $projectspec.spec
    if [ "$buildtype" == "release" ]; then
        if [ "$specrelease" != "" ]; then
            sed -r -i -e '/^Release:./c\Release: '"$specrelease%{?dist}" $projectspec.spec
        fi
    fi
#    if [ "$buildtype" == "release" ] && [ "$version" != "" ]; then
#        # Find lines starting with Version: and replace the whole line with the version requested
#        sed -r -i -e '/^Version:./c\Version: '"$versionmajor"  $projectspec.spec
#    else
#        # Find lines starting with Version: and replace the rest of the line with the versionsnapsuffix
#        sed -r -i -e '/^Version:/s/\s*$/'".$versionsnapsuffix/" $projectspec.spec
#    fi

    # Set the right values in the spec files.
    case "$project" in
    ${projects[$PJ_CONTROLLER]})
        # Set the version for the integration source.
        # Find lines with opendaylight-integration-%{version} and replace %{version} with the version.
        sed -r -i -e '/opendaylight-integration-\%\{version\}/s/\%\{version\}/'"${versions[$PJ_INTEGRATION]}"'/g' \
            $projectspec.spec
        ;;

    ${projects[$PJ_DEPENDENCIES]})
        # Set the version for ovsdb in the dependencies spec.
        # Don't worry about opendaylight-controller version since the dependencies
        # version is the same as the controller version.
        # Find lines with opendaylight-ovsdb-%{version} and replace %{version} with the version.
        sed -r -i -e '/opendaylight-ovsdb-\%\{version\}/s/\%\{version\}/'"${versions[$PJ_OVSDB]}"'/g' \
            $projectspec.spec
        # Find lines with opendaylight-ovsdb-dependencies-%{version} and replace %{version} with the version.
        sed -r -i -e '/opendaylight-ovsdb-dependencies-\%\{version\}/s/\%\{version\}/'"${versions[$PJ_OVSDB]}"'/g' \
            $projectspec.spec
        ;;

    *)
        ;;
    esac

    # Rewrite the mvn command in the rpmbuild if the user requests it.
    if [ "$mockmvn" != "" ]; then
        # Find lines starting with export MAVEN_OPTS= and replace the whole line with $mockmvn
        sed -r -i -e '/^export MAVEN_OPTS=./c\ '"$mockmvn" $projectspec.spec
    fi

    # Build the source RPM for use by mock later.
    #rm -f SRPMS/*.src.rpm
    log $LOGINFO "::::: building $projectspec.src.rpm with rpmbuild"
    rpmbuild -bs --define '%_topdir '"`pwd`" --define '%_sourcedir %{_topdir}' \
       --define "%dist .$pkg_dist_suffix" $projectspec.spec

    rc=$?
    if [ $rc != 0 ]; then
        log $LOGERROR "rpmbuild of $projectspec.src.rpm failed (rc=$rc)."
        exit $RCRPMBUILDERROR
    fi

    log $LOGINFO "::::: building $projectspec.rpm with mock"

    if [ "$buildtype" == "release" ]; then
        resultdir="repo/$projectspec.$pkg_dist_suffix.noarch"
    else
        resultdir="repo/$projectspec.$pkg_dist_suffix.noarch.snap"
    fi

    # Build the rpm using mock.
    # Keep the build because we will need the distribution zip file for later
    # when building the controller-dependencies.rpm.
    eval $mock_cmd $mockdebug -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
        -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
        SRPMS/$projectspec-$versionmajor-*.src.rpm

    rc=$?
    if [ $rc != 0 ]; then
        log $LOGERROR "mock of $projectspec.rpm failed (rc=$rc)."
        exit $RCRMOCKERROR
    fi

    log $LOGINFO "::::: finished building $projectspec.rpm in mock"

    # Copy the distribution zip from the controller and ovsdb projects
    # for use in the dependencies.rpm.
    case "$project" in
    ${projects[$PJ_CONTROLLER]})
        log $LOGINFO "::::: Copying $projectspec distribution.zip."
        eval $mock_cmd $mockdebug -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
            -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
            --copyout \"builddir/build/BUILD/$projectspec-$versionmajor/opendaylight/distribution/opendaylight/target/distribution.opendaylight-osgipackage.zip\" \"$resultdir/$projectspec-$versionmajor.zip\"
        rc1=$?
        ln -sf $resultdir/$projectspec-$versionmajor.zip $tmpbuild
        rc2=$?
        if [ ! -e $tmpbuild/$projectspec-$versionmajor.zip ]; then
            log $LOGERROR "cannot find $projectspec distribution zip file (rc=$rc1:$rc2)."
            exit $RCERROR
        fi
        ;;

    ${projects[$PJ_OVSDB]})
        log $LOGINFO "::::: Copying $projectspec distribution.zip."
        # Grab the version from the pom.xml file.
        # Get the lines between the parent tags, then get the line with the version tag and remove leading space and
        # the tag itself, then remove the trailing tag to be left with the version.
        pomversion=`sed -n -e '/<parent>/,/<\/parent>/p' "$buildroot/${projects[$PJ_OVSDB]}/pom.xml" | sed -n -e '/<version>/s/.*<version>//p' | sed -n -e 's/<\/version>//p'`
        eval $mock_cmd $mockdebug -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
            -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
            --copyout \"builddir/build/BUILD/$projectspec-$versionmajor/distribution/opendaylight/target/distribution.ovsdb-$pomversion-osgipackage.zip\" \"$resultdir/$projectspec-$versionmajor.zip\"
        rc1=$?
        ln -sf $resultdir/$projectspec-$versionmajor.zip $tmpbuild
        rc2=$?
        if [ ! -e $tmpbuild/$projectspec-$versionmajor.zip ]; then
            log $LOGERROR "cannot find $projectspec distribution zip file (rc=$rc1:$rc2)."
            exit $RCERROR
        fi
        ;;

    *)
        ;;
    esac
}

# Main function that builds the rpm's for snapshot's.
function build_snapshot {
    set_versions "$timesuffix" "$versiontype" "$version" "$buildtype"
    mk_git_archives "$timesuffix"

    # Initialize our mock build location (we'll be using --no-clean later)
    # If we don't do the first init we can't build since the environment
    # doesn't get setup correctly!
    if [ $mockinit -eq 1 ]; then
        eval $mock_cmd $mockdebug -r $dist --init
    fi

    start=$PJ_CONTROLLER
    end=$PJ_LAST

    if [ $shortcircuits -ne 0 ]; then
        start=$shortcircuits
    fi

    if [ $shortcircuite -ne 0 ]; then
        end=$shortcircuite
    fi

    echo "start:end = $start:$end"

    for i in `seq $start $end`; do
        build_project "${projects[$i]}" "${versions[$i]}" "${suffix[$i]}"
    done

    log $LOGINFO ":::::"
    log $LOGINFO "::::: All projects have been built"
    log $LOGINFO ":::::"

    push_rpms
}

# Main function that builds the rpm's for release's.
# shague: should be similar to snapshot but use a different version or tag.
# spec files should be updated with correct version. If so, do
function build_release {
    log $LOGINFO "$FUNCNAME: Not implemented yet."
}

function parse_options {
    while true ; do
        case "$1" in
        --debug)
            set -vx; shift;
            ;;

        --mockdebug)
            mockdebug="-v"; shift;
            ;;

        --buildtype)
            shift; buildtype="$1"; shift;
            if [ "$buildtype" != "snapshot" ] && [ "$buildtype" != "release" ]; then
                usage $RCPARMSERROR "Invalid build type.";
            fi
            ;;

        --buildroot)
            shift; buildroot="$1"; shift;
            if [ "$buildroot" == "" ]; then
                usage $RCPARMSERROR "Missing build root.";
            fi
            if [ ! -d "$buildroot" ]; then
                usage $RCPARMSERROR "Invalid build root path."
            fi
            ;;

        --buildtag)
            shift; buildtag="$1"; shift;
            if [ "$buildtag" == ""  ]; then
                usage $RCPARMSERROR "Missing build tag.";
            fi
            ;;

        --cleanroot)
            cleanroot=1; shift;
            ;;

        --cleantmp)
            cleantmp=1; shift;
            ;;

        --getsource)
            shift; getsource="$1"; shift;
            if [ "$getsource" != "clone" ] && [ "$getsource" != "snapshot" ] && \
               [ "$getsource" != "buildroot" ]; then
                usage $RCPARMSERROR "Invalid getsource method.";
            fi
            ;;

        --dist)
            shift; dist="$1"; shift;
            if [ "$dist" == "" ]; then
                usage $RCPARMSERROR "Missing distribution.";
            fi
            ;;

        --distsuffix)
            shift; pkg_dist_suffix="$1"; shift;
            if [ "$pkg_dist_suffix" == "" ]; then
                usage $RCPARMSERROR "Missing package distribution suffix.";
            fi
            ;;

        --versiontype)
            shift; versiontype="$1"; shift;
            if [ "$versiontype" != "user" ] && [ "$versiontype" != "pom" ] && [ "$versiontype" != "spec" ]; then
                usage $RCPARMSERROR "Invalid version type.";
            fi
            ;;

        --specrelease)
            shift; specrelease="$1"; shift;
            if [ "$specrelease" == "" ]; then
                usage $RCPARMSERROR "Missing specrelease.";
            fi
            ;;

        --releasetag)
            releasetag=1; shift;
            ;;

        --version)
            shift; version="$1"; shift;
            if [ "$version" == "" ]; then
                usage $RCPARMSERROR "Missing version.";
            fi
            ;;

        --edversion)
            shift; edversion="$1"; shift;
            if [ "$edversion" == "" ]; then
                usage $RCPARMSERROR "Missing edversion.";
            fi
            ;;

        --branch)
            shift; branch="$1"; shift;
            if [ "$branch" == "" ]; then
                usage $RCPARMSERROR "Missing branch.";
            fi
            depth=1
            ;;

        --repourl)
            shift; repourl="$1"; shift;
            if [ "$repourl" == "" ]; then
                usage $RCPARMSERROR "Missing repo url.";
            fi
            ;;

        --repouser)
            shift; repouser="$1"; shift;
            if [ "$repouser" == "" ]; then
                usage $RCPARMSERROR "Missing repo user.";
            fi
            ;;

        --repopw)
            shift; repopw="$1"; shift;
            if [ "$repopw" == "" ]; then
                usage $RCPARMSERROR "Missing repo pw.";
            fi
            ;;

        --pushrpms)
            pushrpms=1; shift;
            ;;

        --timesuffix)
            shift; timesuffix="$1"; shift;
            if [ "$timesuffix" == ""  ]; then
                usage $RCPARMSERROR "Missing time suffix.";
            fi
            ;;

        --mvn_cmd)
            shift; mvn_cmd="$1"; shift;
            if [ "$mvn_cmd" == "" ]; then
                usage $RCPARMSERROR "Missing mvn_cmd.";
            fi
            ;;

        --mockinit)
            mockinit=1; shift;
            ;;

        --mockmvn)
            shift; mockmvn="$1"; shift;
            if [ "$mockmvn" == "" ]; then
                usage $RCPARMSERROR "Missing mockmvn.";
            fi
            ;;

        --baseURL)
            shift; baseURL="$1"; shift;
            if [ "$baseURL" == "" ]; then
                usage $RCPARMSERROR "Missing baseURL.";
            fi
            ;;

        --baseRepositoryId)
            shift; baseRepositoryId="$1"; shift;
            if [ "$baseRepositoryId" == "" ]; then
                usage $RCPARMSERROR "Missing baseRepositoryId.";
            fi
            ;;

        --shortcircuits)
            shift; shortcircuits=$1; shift;
            ;;

        --shortcircuite)
            shift; shortcircuite=$1; shift;
            ;;

        --listprojects)
            listprojects=1; shift;
            ;;

        -? | -h | --help)
            usage $RCSUCCESS
            ;;
        "")
            break
            ;;
        *)
            log $LOGINFO "Ignoring unknown option: $1"; shift;
        esac
    done
}


#################### main ####################

if [ "$timesuffix" == "" ]; then
    timesuffix="$(date +%F_%T | tr -d .:- | tr _ .)"
fi
date_start=$(date +%s)

parse_options "$@"

if [ $listprojects -eq 1 ]; then
    for i in `seq $PJ_FIRST $PJ_LAST`; do
        echo "$i ${projects[$i]}"
    done
    exit $RCSUCCESS
fi

# Some more error checking...
if [ -z $buildroot ]; then
    log $LOGERROR "Mising buildroot"
    exit $RCPARMSERROR
fi

if [ $cleanroot -eq 1 ] && [ $getsource = "buildroot" ]; then
    log $LOGERROR "Aborting. You probably do not want to clean the directory" \
         "containing the source."
    exit $RCPARMSERROR
fi

if [ "$versiontype" != "user" ] && [ "$version" == "" ]; then
    log $LOGERROR "version type user requires a version"
fi

# Can change tmpbuild to be an index or other tag
if [ -n "$buildtag" ]; then
    tmpbuild="$buildroot/bld_$buildtag"
else
    tmpbuild="$buildroot/bld"
fi

show_vars

if [ $cleanroot -eq 1 ]; then
    rm -rf $buildroot
    mkdir -p $buildroot
fi

if [ $cleantmp -eq 1 ]; then
    rm -rf $tmpbuild
fi

# Setup the temp build directory.
mkdir -p $tmpbuild/repo

# Get the source.
case "$getsource" in
clone)
    clone_source "$depth";

    if [ -n "$branch" ]; then
        checkout_branch $branch
    fi

    if [ $releasetag -eq 1 ]; then
        checkout_release_tag
    fi
    ;;

snapshot)
    snapshot_source;
    exit $RCSUCCESS
    ;;

buildroot)
    cd $buildroot

    # Check if all the projects dirs are really there.
    for i in $gitprojects; do
        if [ ! -d ${projects[$i]} ]; then
            log $LOGERROR "Missing ${projects[$i]}"
            exit $RCPARMSERROR
        fi
    done

    if [ -n "$branch" ]; then
        checkout_branch $branch
    fi

    if [ $releasetag -eq 1 ]; then
        checkout_release_tag
    fi

    ;;
esac
#exit $RCSUCCESS
if [ "$buildtype" == "snapshot" ]; then
    log $LOGINFO "Building a snapshot build"
    build_snapshot
else
    log $LOGINFO "Building a release build"
    build_snapshot
fi

date_end=$(date +%s)
diff=$(($date_end - $date_start))
log $LOGINFO "Build took $(($diff / 3600 % 24)) hours $(($diff / 60 % 60)) minutes and $(($diff % 60)) seconds."

exit $RCSUCCESS
