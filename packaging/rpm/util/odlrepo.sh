#!/bin/bash
#set -vx

mkrepofile=0
mkrepo=0
crrepo=0
cprpms=0
repodir="/home/repo"
yumdir="/etc/yum.repos.d"
reponame="localodl.repo"
rpmdir="~/data/rpmbuild/test1/bld_1/repo"


function usage {
    local rc=$1
    local outstr=$2

    if [ "$outstr" != "" ]; then
        echo "$outstr"
        echo
    fi

    echo "This script is used to create a local yum repo for testing rpm installs."
    echo "The script can make the local repo directory, run createrepo to"
    echo "initialize it as a repo, create the yum repo file and copy rpms to"
    echo "the repo."
    echo
    echo "Usage: `basename $0` [OPTION...]"
    echo
    echo "Script options"
    echo "  --mkrepo           make the repodir"
    echo "  --crrepo           createrepo the repodir"
    echo "  --mkrepofile       name of the yum.repos.d repo file"
    echo "  --cprpms           copy the rpms to the repo"
    echo "  --repodir DIR      directory to make into a repo"
    echo "  --yumdir DIR       yum directory with repo files"
    echo "  --rpmdir DIR       directory with rpms"
    echo
    echo "Help options:"
    echo "  -?, -h, --h, --help  Display this help and exit"
    echo

    exit $rc
}

function parse_options {
    while true ; do
        case "$1" in
        --mkrepofile)
            shift; mkrepofile=1;
            ;;

        --mkrepo)
            shift; mkrepo=1;
            ;;

        --crrepo)
            shift; crrepo=1;
            ;;

        --cprpms)
            shift; cprpms=1;
            ;;

         --reponame)
            shift; reponame="$1"; shift
            if [ "$reponame" = "" ]; then
                usage 1 "Missing repo name.";
            fi
            ;;

         --repodir)
            shift; repodir="$1"; shift
            if [ "$repodir" = "" ]; then
                usage 1 "Missing yum directory.";
            fi
            ;;

         --yumdir)
            shift; yumdir="$1"; shift
            if [ "$yumdir" = "" ]; then
                usage 1 "Missing yum directory.";
            fi
            ;;

         --rpmdir)
            shift; rpmdir="$1"; shift
            if [ "$rpmdir" = "" ]; then
                usage 1 "Missing rpm directory.";
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

function make_repo_file () {
    local yumdir=$1
    local reponame=$2

    rm -f $yumdir/$reponame

    echo "$yumdir/$reponame"
    cat <<EOF > $yumdir/$reponame
[localodl]
name=Local ODL
baseurl=file:///home/repo
enabled=1
gpgcheck=0
metadata_expire=1m

[localodlftp]
name=Local FTP ODL
baseurl=ftp://127.0.0.1/pub
enabled=1
gpgcheck=0
metadata_expire=1m
EOF
}

function make_repo () {
    local repodir=$1

    mkdir -p $repodir
    chmod -R 777 $repodir
}

function create_repo () {
    local repodir=$1

    check_dir $repodir

    createrepo -d $repodir
}

function copy_rpms_to_repo () {
    local rpmdir=$1
    local repodir=$2

    check_dir $rpmdir
    check_dir $repodir

    for rpm in $( find $rpmdir -name *.rpm ); do
        cp $rpm $repodir
    done
}

function main () {
    parse_options "$@"

    eval rpmdir=$rpmdir

    if [ $mkrepo -eq 1 ]; then
        make_repo $repodir
    fi

    if [ $cprpms -eq 1 ]; then
        copy_rpms_to_repo $rpmdir $repodir
    fi

    if [ $crrepo -eq 1 ]; then
        create_repo $repodir
    fi

    if [ $mkrepofile -eq 1 ]; then
        make_repo_file $yumdir $reponame
    fi
}

main "$@"

exit 0
