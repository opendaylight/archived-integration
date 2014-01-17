#!/bin/bash

option=$1;
shift

case "$option" in
base)
    bundlefilter="-bundlefilter org.opendaylight.ovsdb.ovsdb.neutron"
    /usr/share/opendaylight-controller/run.base.sh $bundlefilter "$@"
    ;;

virt-ovsdb)
    bundlefilter="-bundlefilter org.opendaylight.(vtn|opendove)"
    /usr/share/opendaylight-controller/run.sh -virt ovsdb "$@"
    ;;

virt-vtn)
    echo "$option not supported yet"
    #bundlefilter="-bundlefilter org.opendaylight.(affinity|opendove|ovsdb|controller.(arphandler|samples)"
    #/usr/share/opendaylight-controller/run.sh -virt vtn "$@"
    ;;

virt-opendove)
    echo "$option not supported yet"
    #bundlefilter="-bundlefilter org.opendaylight.(ovsdb|vtn)"
    #/usr/share/opendaylight-controller/run.sh -virt vtn "$@"
    ;;

sp)
    echo "$option not supported yet"
    #/usr/share/opendaylight-controller/run.sh sp "$@"
    ;;

-stop)
    /usr/share/opendaylight-controller/run.internal.sh -stop
    ;;

-status)
    /usr/share/opendaylight-controller/run.internal.sh -status
    ;;

*)
    echo "Invalid option: $option"
    ;;
esac

exit 0
