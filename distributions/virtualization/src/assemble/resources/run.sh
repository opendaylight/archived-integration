#!/bin/bash

function usage {
    echo "Please select one of the 3 supported Virtualization technology : \"$0 -virt [ovsdb | opendove | vtn]\""
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
        ODL_VIRT_FILTER="opendove|vtn"
    elif [ "${virt}" == "opendove" ]; then
        ODL_VIRT_FILTER="ovsdb|vtn"
    elif [ "${virt}" == "vtn" ]; then
        ODL_VIRT_FILTER="affinity|opendove|ovsdb|controller.(arphandler|samples)"
    else
        usage
    fi
fi

./run.base.sh -bundlefilter "org.opendaylight.(${ODL_VIRT_FILTER})" "${@:1:$virtIndex-1}" "${@:virtIndex+2}"
