#!/bin/bash

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

*)
    echo "Invalid option: $option"
    ;;
esac

exit -1
