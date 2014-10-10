#!/bin/bash

# Use same path for run.base.sh
RUNSH_DIR=$(dirname $0)
RUN_BASE_SH=${RUNSH_DIR}/run.base.sh

function usage {
    echo -e "You must select one of the 3 supported network virtualization technologies:\n\tovsdb | vtn"
    echo "Usage: $0 -virt {ovsdb | vtn} [advanced options]"
    echo "Advanced options: $($RUN_BASE_SH -help | sed "s;Usage: $RUN_BASE_SH ;;")"
    exit 1
}

virtIndex=0
while true ; do
    (( i += 1 ))
    case "${@:$i:1}" in
        -virt) virtIndex=$i ;;
        "") break ;;
    esac
done

# Virtualization edition select
if [ ${virtIndex} -eq 0 ]; then
    usage
fi

virt=${@:$virtIndex+1:1}
if [ "${virt}" == "" ]; then
    usage
else
    if [ "${virt}" == "ovsdb" ]; then
        ODL_VIRT_FILTER="vtn"
    elif [ "${virt}" == "vtn" ]; then
        ODL_VIRT_FILTER="ovsdb.openstack|controller.(arphandler|samples)"
    else
        usage
    fi
fi

$RUN_BASE_SH -bundlefilter "org.opendaylight.(${ODL_VIRT_FILTER})" "${@:1:$virtIndex-1}" "${@:virtIndex+2}"
