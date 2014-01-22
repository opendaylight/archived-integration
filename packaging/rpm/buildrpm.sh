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
    echo "  --distsuffix SUFFIX    package distribution suffix"
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
    echo "  --mockmvn              replace the maven command used within mock"
    echo
    echo "Help options:"
    echo "  -?, -h, --help  Display this help and exit"
    echo "  --debug         Enable bash debugging output"
    echo "  --mockdebug     Enable mock debugging output"
    exit $rc
}

readonly PJ_INTEGRATION=0
readonly PJ_CONTROLLER=1
readonly PJ_OVSDB=2
readonly PJ_OPENFLOWJAVA=3
readonly PJ_OPENFLOWPLUGIN=4
readonly PJ_DEPENDENCIES=5
readonly PJ_DISTRIBUTION=6

projects[$PJ_INTEGRATION]="integration"
projects[$PJ_CONTROLLER]="controller"
projects[$PJ_OVSDB]="ovsdb"
projects[$PJ_OPENFLOWJAVA]="openflowjava"
projects[$PJ_OPENFLOWPLUGIN]="openflowplugin"
projects[$PJ_DEPENDENCIES]="controller-dependencies"
projects[$PJ_DISTRIBUTION]="distribution"

versions[$PJ_INTEGRATION]=""
versions[$PJ_CONTROLLER]=""
versions[$PJ_OVSDB]=""
versions[$PJ_OPENFLOWJAVA]=""
versions[$PJ_OPENFLOWPLUGIN]=""
versions[$PJ_DEPENDENCIES]=""
versions[$PJ_DISTRIBUTION]=""

suffix[$PJ_INTEGRATION]=""
suffix[$PJ_CONTROLLER]=""
suffix[$PJ_OVSDB]=""
suffix[$PJ_OPENFLOWJAVA]=""
suffix[$PJ_OPENFLOWPLUGIN]=""
suffix[$PJ_DEPENDENCIES]=""
suffix[$PJ_DISTRIBUTION]=""


# Clone the projects.
function clone_source {
    for project in ${projects[*]}; do
        # We only care about a shallow clone (no need to grab the entire project)
        git clone --depth 0 https://git.opendaylight.org/gerrit/p/$project.git $buildroot/$project
    done
}

# Copy the projects from snapshots.
# shague: Fill in with the nexus info.
# Make mk_snapshot_archives that just sets up the version strings.
function snapshot_source {
    log $LOGINFO "$FUNCNAME: Not implemented yet."
}

# Archive the projects to creates the SOURCES for rpmbuild:
# - xz the source for later use by rpmbuild.
# - get the version and git hashes to produce a versions and suffix for each project.
# - copy the archives to the SOURCES dir
# shague: need another archive method for snapshot getsource builds since
# the source did not come from a git repo.
function mk_git_archives {
    local timesuffix=$1

    for i in `seq $PJ_INTEGRATION $PJ_OPENFLOWPLUGIN`; do
        if [ "$version" == "" ]; then
            cd $buildroot/${projects[$i]}
            suffix[$i]="snap.$timesuffix.git.$(git log -1 --pretty=format:%h)"
        else
            suffix[$i]="snap.$version"
        fi

        cd $buildroot/integration/packaging/rpm
        # integration uses the controller.spec because there isn't an integration.spec to query.
        if [ ${projects[$i]} == ${projects[$PJ_INTEGRATION]} ]; then
            versions[$i]="$( rpm -q --queryformat="%{version}\n" --specfile opendaylight-${projects[$PJ_CONTROLLER]}.spec | head -n 1 | awk '{print $1}').${suffix[$i]}"
        else
            versions[$i]="$( rpm -q --queryformat="%{version}\n" --specfile opendaylight-${projects[$i]}.spec | head -n 1 | awk '{print $1}').${suffix[$i]}"
        fi

        cd $buildroot/${projects[$i]}
        git archive --prefix=opendaylight-${projects[$i]}-${versions[$i]}/ HEAD | \
            xz > $tmpbuild/opendaylight-${projects[$i]}-${versions[$i]}.tar.xz

    done

    # Use the controller versions becuase these projects don't have a repo.
    for i in `seq $PJ_DEPENDENCIES $PJ_DISTRIBUTION`; do
        suffix[$i]=${suffix[$PJ_CONTROLLER]}
        versions[$i]=${versions[$PJ_CONTROLLER]}
    done

    # Don't forget any patches.
    cp $buildroot/integration/packaging/rpm/opendaylight-integration-fix-paths.patch $tmpbuild
}

# Pushes rpms to the specified Nexus repository
# This only happens if pushrpms is true
function push_rpms {
    if [ $pushrpms = 1 ]; then
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
suffix:       $pkg_dist_suffix
buildtype:    $buildtype
release:      $release
version:      $version
getsource:    $getsource
buildroot:    $buildroot
buildtag:     $buildtag
tmpbuild:     $tmpbuild
mockmvn:      $mockmvn
mockinit:     $mockinit
time:         $timesuffix
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
    # Find lines starting with Version: and replace the rest of the line with the versionsnapsuffix
    sed -r -i -e '/^Version:/s/\s*$/'".$versionsnapsuffix/" opendaylight-$project.spec

    # Set the write values in the spec files.
    case "$project" in
    ${projects[$PJ_CONTROLLER]})
        # Set the version for the integration source.
        # Find lines with opendaylight-integration-%{version} and replace %{version} with the version.
        sed -r -i -e '/opendaylight-integration-\%\{version\}/s/\%\{version\}/'"${versions[$PJ_INTEGRATION]}"'/g' \
            opendaylight-$project.spec
        ;;

    ${projects[$PJ_DEPENDENCIES]})
        # Set the version for ovsdb in the dependencies spec.
        # Find lines with opendaylight-ovsdb-%{version} and replace %{version} with the version.
        sed -r -i -e '/opendaylight-ovsdb-\%\{version\}/s/\%\{version\}/'"${versions[$PJ_OVSDB]}"'/g' \
            opendaylight-$project.spec
        # Find lines with opendaylight-ovsdb-dependencies-%{version} and replace %{version} with the version.
        sed -r -i -e '/opendaylight-ovsdb-dependencies-\%\{version\}/s/\%\{version\}/'"${versions[$PJ_OVSDB]}"'/g' \
            opendaylight-$project.spec
        ;;

    *)
        ;;
    esac

    # Rewrite the mvn command in the rpmbuild if the user requests it.
    if [ "$mockmvn" != "" ]; then
        # Find lines starting with export MAVEN_OPTS= and repalce the whole line with $mockmvn
        sed -r -i -e '/^export MAVEN_OPTS=./c\ '"$mockmvn" opendaylight-$project.spec
    fi

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

    # Copy the distribution zip from the controller and ovsdb projects
    # for use in the dependencies.rpm.
    case "$project" in
    controller)
        log $LOGINFO "::::: Copying $project distribution.zip."
        eval $mock_cmd $mockdebug -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
            -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
            --copyout \"builddir/build/BUILD/opendaylight-$project-$versionmajor/opendaylight/distribution/opendaylight/target/distribution.opendaylight-osgipackage.zip\" \"$resultdir/opendaylight-$project-$versionmajor.zip\"
        rc1=$?
        ln -sf $resultdir/opendaylight-$project-$versionmajor.zip $tmpbuild
        rc2=$?
        if [ ! -e $tmpbuild/opendaylight-$project-$versionmajor.zip ]; then
            log $LOGERROR "cannot find $project distribution zip file (rc=$rc1:$rc2)."
            exit $RCERROR
        fi
        ;;

    ovsdb)
        log $LOGINFO "::::: Copying $project distribution.zip."
        #todo: Parse pom file to get filename.
        eval $mock_cmd $mockdebug -r $dist --no-clean --no-cleanup-after --resultdir \"$resultdir\" \
            -D \"dist .$pkg_dist_suffix\" -D \"noclean 1\" \
            --copyout \"builddir/build/BUILD/opendaylight-$project-$versionmajor/distribution/opendaylight/target/distribution.$project-1.0.0-SNAPSHOT-osgipackage.zip\" \"$resultdir/opendaylight-$project-$versionmajor.zip\"
        rc1=$?
        ln -sf $resultdir/opendaylight-$project-$versionmajor.zip $tmpbuild
        rc2=$?
        if [ ! -e $tmpbuild/opendaylight-ovsdb-$versionmajor.zip ]; then
            log $LOGERROR "cannot find $project distribution zip file (rc=$rc1:$rc2)."
            exit $RCERROR
        fi
        ;;

    *)
        ;;
    esac
}

# Main function that builds the rpm's for snapshot's.
function build_snapshot {
    mk_git_archives $timesuffix

    # Initialize our mock build location (we'll be using --no-clean later)
    # If we don't do the first init we can't build since the environment
    # doesn't get setup correctly!
    if [ $mockinit -eq 1 ]; then
        eval $mock_cmd $mockdebug -r $dist --init
    fi

    for i in `seq $PJ_CONTROLLER $PJ_DISTRIBUTION`; do
        build_project ${projects[$i]} ${versions[$i]} ${suffix[$i]}
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
                $RCPARMSERROR "Missing distribution.";
            fi
            ;;

        --distsuffix)
            shift; pkg_dist_suffix="$1"; shift;
            if [ "$pkg_dist_suffix" == "" ]; then
                $RCPARMSERROR "Missing package distribution suffix.";
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

        --mockmvn)
            shift; mockmvn="$1"; shift;
            if [ "$mockmvn" == "" ]; then
                $RCPARMSERROR "Missing mockmvn.";
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

timesuffix="$(date +%F_%T | tr -d .:- | tr _ .)"
date_start=$(date +%s)

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
    for i in `seq $PJ_INTEGRATION $PJ_OPENFLOWPLUGIN`; do
        if [ ! -d ${projects[$i]} ]; then
            log $LOGERROR "Missing ${projects[$i]}"
            exit $RCPARMSERROR
        fi
    done
    ;;
esac

if [ "$buildtype" = "snapshot" ]; then
    log $LOGINFO "Building a snapshot build"
    build_snapshot
else
    log $LOGINFO "Release builds are not supported yet."
    build_release
fi

date_end=$(date +%s)
diff=$(($date_end - $date_start))
log $LOGINFO "Build took $(($diff / 3600 % 24)) hours $(($diff / 60 % 60)) minutes and $(($diff % 60)) seconds."

exit $RCSUCCESS
