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
version=""
release=""
repourl=""
repouser=""
repopw=""
dist="fedora-19-x86_64"
pkg_dist_suffix="fc19"
mock_cmd='/usr/bin/mock'
timesuffix=""
vers_controller=""
vers_ovsdb=""
suff_controller=""
suff_ovsdb=""
mockdebug=""
mockinit=0
tmpbuild=""


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
    echo "  --buildtype TYPE       build type, either snapshot or release"
    echo "  --buildroot DIRECTORY  build root path"
    echo "  --buildtag             tag the tmpbuild directory, i.e. Jenkins build number"
    echo "  --cleanroot            clean buildroot directory before building"
    echo "  --cleantmp             clean tmpbuild directory before building"
    echo "  --dist DIST            distribution"
    echo "  --getsource METHOD     method for getting source clone|snapshot|buildroot"
    echo
    echo "Tag options:"
    echo "  --release RELEASE      release tag (not used yet)"
    echo "  --version VERSION      version tag"
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
    echo
    echo "Help options:"
    echo "  -?, -h, --help  Display this help and exit"
    echo "  --debug         Enable bash debugging output"
    echo "  --mockdebug     Enable mock debugging output"
    exit $rc
}

# Clone the projects.
function clone_source {
    # We only care about a shallow clone (no need to grab the entire project)
    git clone --depth 0 https://git.opendaylight.org/gerrit/p/controller.git $buildroot/controller
    git clone --depth 0 https://git.opendaylight.org/gerrit/p/integration.git $buildroot/integration
    git clone --depth 0 https://git.opendaylight.org/gerrit/p/ovsdb.git $buildroot/ovsdb
    #git clone --depth 0 https://git.opendaylight.org/gerrit/p/openflowjava.git $buildroot/openflowjava
    #git clone --depth 0 https://git.opendaylight.org/gerrit/p/openflowplugin.git $buildroot/openflowplugin
}

# Copy the projects from snapshots.
# shague: Fill in with the nexus info.
# Make mk_snapshot_archives that just sets up the version strings.
function snapshot_source {
    log $LOGINFO "$FUNCNAME: Not implemented yet."
}

# xz the source for later use by rpmbuild.
# shague: need another archive method for snapshot getsource builds since
# the source did not come from a git repo.
function mk_git_archives {
    local timesuffix="$(date +%F_%T | tr -d .:- | tr _ .)"

    if [ "$version" == "" ]; then
        cd $buildroot/controller
        suff_controller="snap.$timesuffix.git.$(git log -1 --pretty=format:%h)"
        cd $buildroot/ovsdb
        suff_ovsdb="snap.$timesuffix.git.$(git log -1 --pretty=format:%h)"
    else
        suff_controller="snap.$version"
        suff_ovsdb="snap.$version"
    fi

    cd $buildroot/integration/packaging/rpm
    vers_controller="$( rpm -q --queryformat="%{version}\n" --specfile opendaylight-controller.spec | head -n 1 | awk '{print $1}').$suff_controller"
    vers_ovsdb="$( rpm -q --queryformat="%{version}\n" --specfile opendaylight-ovsdb.spec | head -n 1 | awk '{print $1}').$suff_ovsdb"

    cd $buildroot/controller
    git archive --prefix=opendaylight-controller-$vers_controller/ HEAD | \
        xz > $tmpbuild/opendaylight-controller-$vers_controller.tar.xz

    cd $buildroot/integration
    git archive --prefix=opendaylight-integration-$vers_controller/ HEAD | \
        xz > $tmpbuild/opendaylight-integration-$vers_controller.tar.xz
    cp packaging/rpm/opendaylight-integration-fix-paths.patch $tmpbuild/

    cd $buildroot/ovsdb
    git archive --prefix=opendaylight-ovsdb-$vers_ovsdb/ HEAD | \
        xz > $tmpbuild/opendaylight-ovsdb-$vers_ovsdb.tar.xz
}

# Pushes rpms to the specified Nexus repository
# This only happens if pushrpms is true
function push_rpms {
    if [ $pushrpms = 1 ]; then
        log $LOGINFO "$FUNCNAME: Not implemented yet."
        allrpms=`find $tmpbuild/repo -iname '*.rpm'`
        echo
        log $LOGINFO "RPMS found"
        for i in $allrpms
        do
            log $LOGINFO $i
        done

        log $LOGINFO ":::::"
        log $LOGINFO "::::: pushing RPMs"
        log $LOGINFO ":::::"
        for i in $allrpms
        do
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
distribution: $dist
buildtype:    $buildtype
release:      $release
version:      $version
getsource:    $getsource
buildroot:    $buildroot
buildtag:     $buildtag
tmpbuild:     $tmpbuild
EOF
}

# Build a single project.
function build_project {
    local project=$1
    local versionmajor="$2"
    local versionsnapsuffix="$3"

    log $LOGINFO ":::::"
	log $LOGINFO "::::: building opendaylight-$project.rpm"
	log $LOGINFO ":::::"

    cp -f $buildroot/integration/packaging/rpm/opendaylight-$project.spec \
        $tmpbuild

    cd $tmpbuild
	sed -r -i -e '/^Version:/s/\s*$/'".$versionsnapsuffix/" opendaylight-$project.spec

    # Build the source RPM for use by mock later.
	#rm -f SRPMS/*.src.rpm
	log $LOGINFO "::::: building opendaylight-$project.src.rpm in rpmbuild"
	rpmbuild -bs --define '%_topdir '"`pwd`" --define '%_sourcedir %{_topdir}' \
       --define "%dist .$pkg_dist_suffix" opendaylight-$project.spec

    rc=$?
    if [ $rc != 0 ]; then
        log $LOGERROR "rpmbuild of $project.src.rpm failed (rc=$rc)."
        exit $RCRPMBUILDERROR
    fi

	log $LOGINFO "::::: building opendaylight-$project.rpm in mock"

	resultdir="repo/$project.$pkg_dist_suffix.noarch.snap"

    # Build the rpm using mock.
    # Keep the build because we will need the distribution zip file for later
    # when building the controller-dependencies.rpm.
    eval $mock_cmd $mockdebug -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
        -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
        SRPMS/opendaylight-$project-$versionmajor-*.src.rpm

    rc=$?
    if [ $rc != 0 ]; then
        log $LOGERROR "mock of $project.rpm failed (rc=$rc)."
        exit $RCRMOCKERROR
    fi

    # Copy the distribution zip for use in the dependencies.rpm.
    case "$project" in
    controller)
        log $LOGINFO "::::: Copying $project distribution.zip."
        eval $mock_cmd $mockdebug -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
            -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
            --copyout \"builddir/build/BUILD/opendaylight-$project-$versionmajor/opendaylight/distribution/opendaylight/target/distribution.opendaylight-osgipackage.zip\" \"$resultdir/opendaylight-$project-$versionmajor.zip\"
        rc1=$?
        ln -sf $resultdir/opendaylight-$project-$versionmajor.zip \
            $tmpbuild
        rc2=$?
        if [ ! -e $tmpbuild/opendaylight-$project-$versionmajor.zip ]; then
            log $LOGERROR "cannot find $project distribution zip file (rc=$rc1:$rc2)."
            exit $RCERROR
        fi
        ;;

    ovsdb)
        log $LOGINFO "::::: Copying $project distribution.zip."
        # Parse pom file to get filename.
        eval $mock_cmd $mockdebug -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
            -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
            --copyout \"builddir/build/BUILD/opendaylight-$project-$versionmajor/distribution/opendaylight/target/distribution.$project-1.0.0-SNAPSHOT-osgipackage.zip\" \"$resultdir/opendaylight-$project-$versionmajor.zip\"
        rc1=$?

        ln -sf $resultdir/opendaylight-$project-$versionmajor.zip \
            $tmpbuild/opendaylight-ovsdb-$vers_controller.zip
        rc2=$?
        if [ ! -e $tmpbuild/opendaylight-ovsdb-$vers_controller.zip ]; then
            log $LOGERROR "cannot find $project distribution zip file (rc=$rc1:$rc2)."
            exit $RCERROR
        fi
        ;;

    controller-dependencies|controller-distribution)
        ;;
    esac
}

# Main function that builds the rpm's for snapshot's.
function build_snapshot {
	mk_git_archives

    # Initialize our mock build location (we'll be using --no-clean later)
    # If we don't do the first init we can't build since the environment
    # doesn't get setup correctly!
    if [ mockinit -eq 1 ]; then
        eval $mock_cmd $mockdebug -r $dist --init
    fi
# Test code for short-cicuit when Nexus isn't behaving.
if [ 0 -eq 1 ]; then
    opendaylight-ovsdb-0.1.0.snap.20140112.161313.git.43aa583

    vers_controller="0.1.0.snap.20140112.161313.git.43aa583"
    vers_ovsdb="0.1.0.snap.20140112.161313.git.43aa583"

    suff_controller="snap.20140112.161313.git.43aa583"
    suff_ovsdb="snap.20140112.161313.git.43aa583"
fi

	build_project controller $vers_controller $suff_controller
	build_project ovsdb $vers_ovsdb $suff_ovsdb
	build_project controller-dependencies $vers_controller $suff_controller
	build_project distribution $vers_controller $suff_controller

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
                $RCPARMSERROR "Missing distribution.";
            fi
            ;;

        --release)
            shift; release="$1"; shift;
            if [ "$release" == "" ]; then
                $RCPARMSERROR "Missing release.";
            fi
            ;;

        --version)
            shift; version="$1"; shift;
            if [ "$version" == "" ]; then
                $RCPARMSERROR "Missing version.";
            fi
            ;;

        --repourl)
            shift; repourl="$1"; shift;
            if [ "$repourl" == "" ]; then
                $RCPARMSERROR "Missing repo url.";
            fi
            ;;

        --repouser)
            shift; repouser="$1"; shift;
            if [ "$repouser" == "" ]; then
                $RCPARMSERROR "Missing repo user.";
            fi
            ;;

        --repopw)
            shift; repopw="$1"; shift;
            if [ "$repopw" == "" ]; then
                $RCPARMSERROR "Missing repo pw.";
            fi
            ;;

        --pushrpms)
            pushrpms=1; shift;
            ;;

        --mvn_cmd)
            shift; mvn_cmd="$1"; shift;
            if [ "$mvn_cmd" == "" ]; then
                $RCPARMSERROR "Missing mvn_cmd.";
            fi
            ;;

        --baseURL)
            shift; baseURL="$1"; shift;
            if [ "$baseURL" == "" ]; then
                $RCPARMSERROR "Missing baseURL.";
            fi
            ;;

        --baseRepositoryId)
            shift; baseRepositoryId="$1"; shift;
            if [ "$baseRepositoryId" == "" ]; then
                $RCPARMSERROR "Missing baseRepositoryId.";
            fi
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

parse_options "$@"

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
    clone_source;
    ;;

snapshot)
    snapshot_source;
    exit $RCSUCCESS
    ;;

buildroot)
    cd $buildroot
    if [ ! -d "controller" ] || [ ! -d "integration" ] || [ ! -d "ovsdb" ]; then
        log $LOGERROR "Could not find all required projects in buildroot."
        log $LOGERROR "Projects include controller, integration and ovsdb."
        exit $RCPARMSERROR
    fi
    ;;
esac

if [ "$buildtype" = "snapshot" ]; then
    log $LOGINFO "Building a snapshot build"
    build_snapshot
else
    log $LOGINFO "Release builds are not supported yet."
    build_release
fi

exit $RCSUCCESS
