#!/bin/bash
#set -vx

archive=0
cloneremote=0
clonelocal=0
gitdir="~/git"
rpmbuilddir="~/rpmbuild"
version="0.1.0"

projects=(integration controller ovsdb openflowjava openflowplugin lispflowmapping snmp4sdn affinity yangtools bgpcep opendove)

function usage {
    local rc=$1
    local outstr=$2

    if [ "$outstr" != "" ]; then
        echo "$outstr"
        echo
    fi

    echo "This script is used to prepare a buildrpm environment."
    echo "The script can archive and existing git dir containing all the projects,"
    echo "clone all projects from a remote repo or from a local repo."
    echo
    echo "Usage: `basename $0` [OPTION...]"
    echo
    echo "Script options"
    echo "  --archive          archive all the projects in the git directory"
    echo "  --cloneremote      clone all the projects in the remote repo"
    echo "  --clonelocal       clone all the projects in the local repo"
    echo "  --gitdir DIR       git root directory where projects are cloned"
    echo "  --rpmbuilddir DIR  rpmbuild root directory where rpms are built"
    echo "  --version VERSION  version tag to use for archives"
    echo
    echo "Help options:"
    echo "  -?, -h, --h, --help  Display this help and exit"
    echo

    exit $rc
}

function parse_options {
    while true ; do
        case "$1" in
        --archive)
            shift; archive=1;
            ;;

        --cloneremote)
            shift; cloneremote=1;
            ;;

        --clonelocal)
            shift; clonelocal=1;
            ;;

         --gitdir)
            shift; gitdir="$1"; shift
            if [ "$gitdir" = "" ]; then
                usage 1 "Missing git directory.";
            fi
            ;;

         --outdir)
            shift; outdir="$1"; shift
            if [ "$outdir" = "" ]; then
                usage 1 "Missing out directory.";
            fi
            ;;

         --rpmbuilddir)
            shift; rpmbuilddir="$1"; shift
            if [ "$rpmbuilddir" = "" ]; then
                usage 1 "Missing rpmbuild directory.";
            fi
            ;;

         --version)
            shift; version="$1"; shift
            if [ "$version" = "" ]; then
                usage 1 "Missing version.";
            fi
            ;;

        -? | -h | --h | --help)
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

function check_dir () {
    local dir=$1

    if [ ! -d "$dir" ]; then
        usage 1 "Invalid dir: $dir"
    fi
}

function archive_projects () {
    local gitdir=$1
    local rpmbuilddir=$2
    local version=$3

    check_dir "$gitdir"
    check_dir "$rpmbuilddir"

    cd $gitdir
    mkdir -p zips

    for project in ${projects[*]}; do
        cd $gitdir/$project
        zipfile=../zips/opendaylight-$project-$version.tar.xz
        echo "Archiving $project to $zipfile"
        git archive --prefix=opendaylight-$project-$version/ HEAD | xz > $zipfile
        src=$gitdir/zips/opendaylight-$project-$version.tar.xz
        echo "Linking $src to $rpmbuilddir/SOURCES"
        ln -sf $src $rpmbuilddir/SOURCES
    done
}

function clone_remote () {
    local outdir=$1

    mkdir -p $outdir
    cd $outdir

    for project in ${projects[*]}; do
        echo "Cloning $project to $outdir/$project"
        git clone https://git.opendaylight.org/gerrit/p/$project.git
    done
}

function clone_local () {
    local gitdir=$1
    local outdir=$2

    mkdir -p $outdir
    cd $outdir

    check_dir "$gitdir"

    for project in ${projects[*]}; do
        echo "Cloning $project to $outdir/$project"
        git clone $gitdir/$project
    done
}

function main () {
    parse_options "$@"

    eval gitdir=$gitdir
    eval rpmbuilddir=$rpmbuilddir


    if [ ! -d "$gitdir" ]; then
        usage 1 "Invalid path."
    fi

    if [ $archive -eq 1 ]; then
        archive_projects "$gitdir" "$rpmbuilddir" "$version"
    fi

    if [ $cloneremote -eq 1 ]; then
        clone_remote $outdir
    fi

    if [ $clonelocal -eq 1 ]; then
        clone_local $gitdir $outdir
    fi
}

main "$@"

exit 0
