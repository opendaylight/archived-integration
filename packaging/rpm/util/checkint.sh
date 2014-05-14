#!/bin/bash
#set -vx

options=$1
gitdir=$2

function usage {
    local rc=$1
    local outstr=$2

    if [ "$outstr" != "" ]; then
        echo "$outstr"
        echo
    fi

    echo "This script is used to validate the rpm builds for each edition."
    echo "The script will compare the different editions against each other"
    echo "to identify the proper filters when starting the controller,"
    echo "list the dependencies in the different editions and identify"
    echo "any inconsistencies between the edition poms and the project specs."
    echo
    echo "Usage: `basename $0` [OPTION...]"
    echo
    echo "Test options:"
    echo "  --options OPTIONS  List of test options. Available options:"
    echo "                     integration: compare integration editions"
    echo "                     pom: get pom dependencies from integration poms"
    echo "                     spec: compare projects specs against the pom dependencies"
    echo "  --gitdir DIR       git root directory where projects are cloned"
    echo
    echo "Help options:"
    echo "  -?, -h, --h, --help  Display this help and exit"
    echo

    exit $rc
}

function parse_options {
    while true ; do
        case "$1" in
        --options)
            shift; options="$1"; shift
            ;;

         --gitdir)
            shift; gitdir="$1"; shift
            if [ "$gitdir" = "" ]; then
                usage 1 "Missing directory.";
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

function array_contains () {
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in "${!array}"; do
        if [ $element = $seeking ]; then
            in=0
            break
        fi
    done
    return $in
}


function compare_integration () {
    local gitdir=$1

    echo
    echo "========================================================================="
    echo "                          Comparing dirs"
    echo "========================================================================="

    cd $gitdir/integration

    rm -rf /tmp/base/*
    basezip=$(find . -name "*distributions-base*.zip")
    unzip -qd /tmp/base $basezip

    rm -rf /tmp/virt/*
    virtzip=$(find . -name "*distributions-virtualization*.zip")
    unzip -qd /tmp/virt $virtzip

    rm -rf /tmp/sp/*
    spzip=$(find . -name "*distributions-serviceprovider*.zip")
    unzip -qd /tmp/sp $spzip

    # Compare one edition against another.

    echo
    echo "Compare base and virt:"
    echo "-------------------------------------------------------------------------"
    diff -qr /tmp/base/opendaylight/ /tmp/virt/opendaylight/
    echo
    echo "Compare base and sp:"
    echo "-------------------------------------------------------------------------"
    diff -qr /tmp/base/opendaylight/ /tmp/sp/opendaylight/
    echo
    echo "Compare virt and sp:"
    echo "-------------------------------------------------------------------------"
    diff -qr /tmp/virt/opendaylight/ /tmp/sp/opendaylight/

    # Compare one edition against the other two.

    rm -rf /tmp/base_virt
    mkdir /tmp/base_virt
    cp -rf /tmp/base/* /tmp/base_virt/
    cp -rf /tmp/virt/* /tmp/base_virt/

    rm -rf /tmp/base_sp
    mkdir /tmp/base_sp
    cp -rf /tmp/base/* /tmp/base_sp/
    cp -rf /tmp/sp/* /tmp/base_sp/

    rm -rf /tmp/virt_sp
    mkdir /tmp/virt_sp
    cp -rf /tmp/virt/* /tmp/virt_sp/
    cp -rf /tmp/sp/* /tmp/virt_sp/

    echo
    echo
    echo "Compare base and virt_sp."
    echo "-------------------------------------------------------------------------"
    diff -qr /tmp/base/opendaylight/ /tmp/virt_sp/opendaylight/
    echo
    echo "Compare virt and base_sp. Useful to see what virt pulls in - look for Only in /tmp/virt."
    echo "-------------------------------------------------------------------------"
    diff -qr /tmp/virt/opendaylight/ /tmp/base_sp/opendaylight/
    echo
    echo "Compare sp and base_virt. Useful to see what sp pulls in - look for Only in /tmp/sp."
    echo "-------------------------------------------------------------------------"
    diff -qr /tmp/sp/opendaylight/ /tmp/base_virt/opendaylight/
}

function check_affinity () {
#	allaffinity=$(find /tmp/virt -name "*affinity.*.jar")
#	while read line; do
#		if [ "line" ]
    echo "here"
}

function read_dom () {
    local IFS=\>
    read -d \< ENTITY CONTENT
}

function read_poms () {
    local gitdir="$1"
    local distribution="$2"
    local pomfile=$gitdir/integration/distributions/$distribution/pom.xml
    local FILE=$pomfile
    local i=$pomcnt
    local groupy=0
    local state="null"

    echo
    echo "read_poms $gitdir $distribution"
    echo "-------------------------------------------------------------------------"

    while read_dom; do
        case "$state" in
        null)
            if [ "$ENTITY" = "dependencies" ]; then
                state="dependencies"
            fi
            ;;

        dependencies)
            case "$ENTITY" in
            groupId)
                groupIds[i]=$CONTENT
                groups=1
                editions[i]=$distribution
                ;;

            artifactId)
                if [ $groups -eq 1 ]; then
                    artifactIds[i]=$CONTENT
                fi
                ;;

            version)
                if [ $groups -eq 1 ]; then
                    versions[i]=$CONTENT
                    groups=0
                    ((i++))
                fi
                ;;

            /dependencies)
                state="done"
                break
                ;;
            esac
            ;;
        esac
    done < "$pomfile"

    end=$((i-1))
    for index in `seq $pomcnt $end`; do
        echo "$index artifact: ${groupIds[$index]}.${artifactIds[$index]}-${versions[$index]}"
    done

    pomcnt=$i
}

function check_poms () {
    local gitdir=$1
    pomcnt=0

    echo
    echo "========================================================================="
    echo "                          Checking poms"
    echo "========================================================================="

    read_poms "$gitdir" "base"
    read_poms "$gitdir" "serviceprovider"
    read_poms "$gitdir" "virtualization"
}

function read_spec () {
    local gitdir="$1"
    local project="$2"
    local specfile=$gitdir/integration/packaging/rpm/opendaylight-$project.spec
    local FILE=$specfile
    local state="null"
    local i=0

    unset specarts

    echo
    echo "read_spec $gitdir $project"
    echo "-------------------------------------------------------------------------"

    while read line; do
        case "$state" in
        null)
            if [ "$line" = "done <<'.'" ]; then
                state="artifacts"
            fi
            ;;

        artifacts)
            if [ "$line" = "." ]; then
                state="done"
                break
            else
                specarts[i]=$line
                ((i++))
            fi
            ;;
        esac
    done < "$specfile"

    for index in ${!specarts[*]}; do
        echo "$index spec artifact: ${specarts[$index]}"
    done
}


function check_project () {
    local gitdir=$1
    local project=$2
    local specfile=$gitdir/integration/packaging/rpm/opendaylight-$project.specfile
    local k=0

    unset notfoundarts
    unset notfoundeds

    echo
    echo "check_project $gitdir $project"
    echo "-------------------------------------------------------------------------"

    read_spec "$gitdir" "$project"

    for i in ${!groupIds[*]}; do
        if [ ${groupIds[$i]} = "org.opendaylight.$project" ]; then
            found=0
            for j in ${!specarts[*]}; do
                specart=$(echo ${specarts[$j]} | sed -e "s/-\*.*//")
                artifactId=${artifactIds[$i]}
                if [ "$specart" = "$artifactId" ]; then
                    found=1
                    break
                fi
            done

            if [ $found -eq 0 ]; then
                notfoundeds[k]=${editions[$i]}
                notfoundarts[k]=${artifactIds[$i]}
                ((k++))
            fi
        fi
    done

    for index in ${!notfoundarts[*]}; do
        echo ">>>>> $index missing artifact: ${notfoundeds[$index]}: ${notfoundarts[$index]}"
    done
}

function check_specs () {
    local gitdir=$1

    echo
    echo "========================================================================="
    echo "                          Checking specs"
    echo "========================================================================="

    check_project "$gitdir" "affinity"
    check_project "$gitdir" "bgpcep"
    check_project "$gitdir" "lispflowmapping"
    check_project "$gitdir" "snmp4sdn"
    check_project "$gitdir" "yangtools"
}

function main () {
    parse_options "$@"

    if [ ! -d "$dir" ]; then
        usage 1 "Invalid path."
    fi

}

main "$@"

exit 0
