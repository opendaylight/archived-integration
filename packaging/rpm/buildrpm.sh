#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>

# shague todo:
# - Add -r option for mock to choose the distribution
# - add option to pass in spec file name, maybe use spec.in template
# - add option to pass in version and release

#set -vx

buildtype="snapshot"
buildroot=`pwd`
buildnumber=0
cleanroot=0
getsource="buildroot"
version=""
release=""
versionsnapsuffix=""
versionmajor=""
repourl=""
repouser=""
repopw=""
dist="fedora-19-x86_64"
pkg_dist_suffix="fc19"
mock_cmd='/usr/bin/mock'


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
    echo "  --buildnumber NUMBER   jenkins build number"
    echo "  --cleanroot            clean buildroot directory before building"
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
    echo "Help options:"
    echo "  -?, -h, --help  Display this help and exit"
    echo "  --debug         Enable bash debugging output"
    exit $rc
}

# Make a snapshot version tag using the git hash and date
# shague: Modify to use ODL build numbering"
function mk_versionsnapsuffix {
    if [ "$version" = "" ]; then
        cd $buildroot/controller
        versionsnapsuffix="snap.$(date +%F_%T | tr -d .:- | tr _ .).git.$(git log -1 --pretty=format:%h)"
    else
        versionsnapsuffix="snap.$version"
    fi
}

# Clone the projects.
function clone_source {
    # We only care about a shallow clone (no need to grab the entire project)
    git clone --depth 0 https://git.opendaylight.org/gerrit/p/controller.git $buildroot/controller
    git clone --depth 0 https://git.opendaylight.org/gerrit/p/integration.git $buildroot/integration
}

# Copy the projects from snapshots.
# shague: Fill in with the nexus info.
function snapshot_source {
    echo "$FUNCNAME: Not implemented yet."
}

# xz the source for later use by rpmbuild.
# shague: need another archive method for snapshot getsource builds since
# the source did not come from a git repo.
function mk_archives {
    cd $buildroot/integration/packaging/rpm/fedora
    git archive HEAD opendaylight-controller.sysconfig opendaylight-controller.systemd \
        | xz > $buildroot/tmpbuild/opendaylight-controller-integration-$versionmajor.tar.xz

    cd $buildroot/controller
    git archive --prefix=opendaylight-controller-$versionmajor/ HEAD | \
        xz > $buildroot/tmpbuild/opendaylight-controller-$versionmajor.tar.xz
}

# shague: Fill in with Nexus info.
function push_rpms {
    echo "$FUNCNAME: Not implemented yet."
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
EOF
}

# Main function that builds the rpm's for snapshot's.
function build_snapshot {
    cp -f $buildroot/integration/packaging/rpm/fedora/opendaylight-controller.spec \
        $buildroot/tmpbuild

    mk_versionsnapsuffix

	cd $buildroot/tmpbuild

    # append snap suffix to version
	versionmajor="$( rpm -q --queryformat="%{version}\n" --specfile opendaylight-controller.spec | head -n 1 | awk '{print $1}').$versionsnapsuffix"

# test code to short circuit the controller build
#if [ 2 = 1 ]; then
	sed -r -i -e '/^Version:/s/\s*$/'".$versionsnapsuffix/" opendaylight-controller.spec

	mk_archives

	cd $buildroot/tmpbuild
	#name="$(rpm -q --queryformat="%{name}\n" --specfile *.spec | head -n 1)"

    # Build the source RPM for use by mock later.
	#rm -f SRPMS/*.src.rpm
	rpmbuild -bs --define '%_topdir '"`pwd`" --define '%_sourcedir %{_topdir}' \
       --define "%dist .$pkg_dist_suffix" opendaylight-controller.spec

    if [ $? != 0 ]; then
        echo "rpmbuild of controller.src.rpm failed."
        exit 2
    fi

	echo ":::::"
	echo "::::: building opendaylight-controller.rpm in mock"
	echo ":::::"

	resultdir="repo/controller.$pkg_dist_suffix.noarch.snap"

    # Initialize our mock build location (we'll be using --no-clean later)
    # If we don't do the first init we can't build since the environment
    # doesn't get setup correctly!
    eval $mock_cmd -r $dist --init

    # Build the rpm using mock.
    # Keep the build because we will need the controller.zip file for later
    # when building the controller-dependencies.rpm.
    eval $mock_cmd -v -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
        -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
        SRPMS/opendaylight-controller-$versionmajor-*.src.rpm

    if [ $? != 0 ]; then
        echo "mock of controller.src.rpm failed."
        exit 2
    fi

#else
#    versionmajor=0.1.0.snap.20131203.165045.git.c406e47
#    versionsnapsuffix=snap.20131203.165045.git.c406e47
#    resultdir="repo/controller.$pkg_dist_suffix.noarch.snap"
#fi

    # Now build the dependencies RPM

    # Copy the controller.zip for use in the dependencies.rpm.
	eval $mock_cmd -v -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
        -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
        --copyout \"builddir/build/BUILD/opendaylight-controller-$versionmajor/opendaylight/distribution/opendaylight/target/distribution.opendaylight-osgipackage.zip\" \"$resultdir/opendaylight-controller-$versionmajor.zip\"

    ln -sf $resultdir/opendaylight-controller-$versionmajor.zip \
        $buildroot/tmpbuild

    cp -f $buildroot/integration/packaging/rpm/fedora/opendaylight-controller-dependencies.spec \
        $buildroot/tmpbuild
    sed -r -i -e '/^Version:/s/\s*$/'".$versionsnapsuffix/" opendaylight-controller-dependencies.spec
    rpmbuild -bs --define '%_topdir '"`pwd`" --define '%_sourcedir %{_topdir}' \
        --define "%dist .$pkg_dist_suffix" opendaylight-controller-dependencies.spec

    if [ $? != 0 ]; then
        echo "rpmbuild of controller-dependencies.src.rpm failed."
        exit 2
    fi

    echo ":::::"
    echo "::::: building opendaylight-controller-dependencies.rpm in mock"
    echo ":::::"

    resultdir="repo/controller-dependencies.$pkg_dist_suffix.noarch.snap"

    eval $mock_cmd -v -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
        -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
        SRPMS/opendaylight-controller-dependencies-$versionmajor-*.src.rpm

    if [ $? != 0 ]; then
        echo "mock of controller-dependencies.src.rpm failed."
        exit 2
    fi

    push_rpms
}

# Main function that builds the rpm's for release's.
# shague: should be similar to snapshot but use a different version or tag.
function build_release {
    echo "$FUNCNAME: Not implemented yet."
}

function parse_options {
    while true ; do
        case "$1" in
        --debug)
            set -vx; shift;
            ;;

        --buildtype)
            shift; buildtype="$1"; shift;
            if [ "$buildtype" != "snapshot" ] && [ "$buildtype" != "release" ]; then
                usage 1 "Invalid build type.";
            fi
            ;;

        --buildroot)
            shift; buildroot="$1"; shift;
            if [ "$buildroot" == "" ]; then
                usage 1 "Missing build root.";
            fi
            if [ ! -d "$buildroot" ]; then
                usage 1 "Invalid build root path."
            fi
            ;;

        --buildnumber)
            shift; buildnumber="$1"; shift;
            if [ "$buildnumber" == ""  ]; then
                usage 1 "Missing build number.";
            fi
            ;;

        --cleanroot)
            cleanroot=1; shift;
            ;;

        --getsource)
            shift; getsource="$1"; shift;
            if [ "$getsource" != "clone" ] && [ "$getsource" != "snapshot" ] && \
               [ "$getsource" != "buildroot" ]; then
                usage 1 "Invalid getsource method.";
            fi
            ;;

        --dist)
            shift; dist="$1"; shift;
            if [ "$dist" == "" ]; then
                usage 1 "Missing distribution.";
            fi
            ;;

        --release)
            shift; release="$1"; shift;
            if [ "$release" == "" ]; then
                usage 1 "Missing release.";
            fi
            ;;

        --version)
            shift; version="$1"; shift;
            if [ "$version" == "" ]; then
                usage 1 "Missing version.";
            fi
            ;;

        --repourl)
            shift; repourl="$1"; shift;
            if [ "$repourl" == "" ]; then
                usage 1 "Missing repo url.";
            fi
            ;;

        --repouser)
            shift; repouser="$1"; shift;
            if [ "$repouser" == "" ]; then
                usage 1 "Missing repo user.";
            fi
            ;;

        --repopw)
            shift; repopw="$1"; shift;
            if [ "$repopw" == "" ]; then
                usage 1 "Missing repo pw.";
            fi
            ;;

        -? | -h | --help)
            usage 0
            ;;
        "")
            break
            ;;
        *)
            echo "Ignoring unknown option: $1"; shift;
        esac
    done
}


#################### main ####################

parse_options "$@"

# Some more error checking...
if [ $cleanroot = 1 ] && [ $getsource = "buildroot" ]; then
    echo "Aborting. You probably do not want to clean the directory" \
         "containing the source."
    exit 1
fi

show_vars

if [ $cleanroot = 1 ]; then
    rm -rf $buildroot
    mkdir -p $buildroot
fi

# Setup the temp build directory.
mkdir -p $buildroot/tmpbuild/repo

# Get the source.
case "$getsource" in
clone)
    clone_source;
    ;;

snapshot)
    snapshot_source;
    ;;

buildroot)
    if [ ! -d "controller" ] || [ ! -d "integration" ]; then
        echo "Problem with controller or integration projects in buildroot."
    fi
    ;;
esac

if [ "$buildtype" = "snapshot" ]; then
    echo "Building a snapshot build"
    build_snapshot
else
    build_release
fi

exit 0
