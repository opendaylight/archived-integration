#!/bin/bash

function usage {
    echo "Please select one of the 3 supported Virtualization technology : \"run.sh -virt [ovsdb | opendove | vtn]\""
    exit 1
}
while true ; do
    case "$1" in
        -virt) shift; virt="$1"; shift ;;
        "") break ;;
        *) shift ;;
    esac
done

# Virtualization edition select
if [ "${virt}" == "" ]; then
    usage
else
    if [ "${virt}" == "ovsdb" ]; then
        ODL_VIRT_FILTER="opendove|vtn"
    elif [ "${virt}" == "opendove" ]; then
        ODL_VIRT_FILTER="ovsdb|vtn"
    elif [ "${virt}" == "vtn" ]; then
        ODL_VIRT_FILTER="opendove|ovsdb"
    else
        usage
    fi
fi

./run.base.sh -Dfelix.fileinstall.filter="^(?!org.opendaylight.(${ODL_VIRT_FILTER})).*" "$@"
