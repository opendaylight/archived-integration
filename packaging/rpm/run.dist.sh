#!/bin/bash

usage() {
    echo -e "Usage:\t$0 base|virt-ovsdb|virt-vtn|virt-opendove|sp|-stop|-status|help\n"

    echo -e "\tbase: base controller edition, good for simple testing"
    echo -e "\tvirt-ovsdb: virtualization controller edition based on ovsdb"
    echo -e "\tvirt-vtn: virtualization controller edition based on vtn
    (not supported yet)"
    echo -e "\tvirt-opendove: virtualization controller edition based on opendove (not supported yet)"
    echo -e "\tsp: service provider controller edition (not supported yet)"
    echo -e "\t-stop: stop the controller"
    echo -e "\t-status: check if controller is currently running"
    echo -e "\thelp: generate this help text"
}

option=$1;
shift

case "$option" in
base)
    bundlefilter="-bundlefilter org.opendaylight.ovsdb.ovsdb.neutron"
    exec /usr/share/opendaylight-controller/run.base.sh $bundlefilter "$@"
    ;;

virt-ovsdb)
    bundlefilter="-bundlefilter org.opendaylight.(vtn|opendove)"
    exec /usr/share/opendaylight-controller/run.sh -virt ovsdb "$@"
    ;;

virt-vtn)
    echo "$option not supported yet"
    #bundlefilter="-bundlefilter org.opendaylight.(affinity|opendove|ovsdb|controller.(arphandler|samples)"
    #exec /usr/share/opendaylight-controller/run.sh -virt vtn "$@"
    ;;

virt-opendove)
    echo "$option not supported yet"
    #bundlefilter="-bundlefilter org.opendaylight.(ovsdb|vtn)"
    #exec /usr/share/opendaylight-controller/run.sh -virt opendove "$@"
    ;;

sp)
    echo "$option not supported yet"
    #exec /usr/share/opendaylight-controller/run.sh sp "$@"
    ;;

-stop)
    exec /usr/share/opendaylight-controller/run.internal.sh -stop
    ;;

-status)
    exec /usr/share/opendaylight-controller/run.internal.sh -status
    ;;

help)
    usage
    exit 0
    ;;
*)
    echo "Invalid option: $option"
    usage
    ;;
esac

exit -1
