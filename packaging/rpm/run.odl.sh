#!/bin/bash

usage() {
    echo -e "Usage:\t$0 base|virt-ovsdb|virt-vtn|virt-opendove|virt-affinity|sp|-stop|-status|help\n"

    echo -e "\tbase: base controller edition, good for simple testing"
    echo -e "\tvirt-ovsdb: virtualization controller edition based on ovsdb"
    echo -e "\tvirt-vtn: virtualization controller edition based on vtn (not supported yet)"
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
    filter="affinity|\
opendove|ovsdb.ovsdb.neutron|vtn|\
bgpcep|lispflowmapping|snmp4sdn|\
yangtools.model.(ietf-ted-2013|ietf-topology-isis-2013|ietf-topology-2013|\
ietf-topology-l3-unicast-igp-2013|ietf-topology-ospf-2013)"

    bundlefilter="-bundlefilter org.opendaylight.(${filter})"
    exec /usr/share/opendaylight-controller/run.base.sh $bundlefilter "$@"
    ;;

virt-ovsdb)
    filter="\
opendove|vtn|\
bgpcep|lispflowmapping|snmp4sdn|\
yangtools.model.(ietf-ted-2013|ietf-topology-isis-2013|ietf-topology-2013|\
ietf-topology-l3-unicast-igp-2013|ietf-topology-ospf-2013)"

    bundlefilter="-bundlefilter org.opendaylight.(${filter})"
    exec /usr/share/opendaylight-controller/run.base.sh $bundlefilter "$@"
    ;;

virt-opendove)
    echo "$option not supported yet"
    filter="\
ovsdb|vtn|\
bgpcep|lispflowmapping|snmp4sdn|\
yangtools.model.(ietf-ted-2013|ietf-topology-isis-2013|ietf-topology-2013|\
ietf-topology-l3-unicast-igp-2013|ietf-topology-ospf-2013)"

    bundlefilter="-bundlefilter org.opendaylight.(${filter})"
    exec /usr/share/opendaylight-controller/run.base.sh $bundlefilter "$@"
    ;;

virt-vtn)
    echo "$option not supported yet"
    filter="affinity|controller.(arphandler|samples)|\
opendove|ovsdb|\
bgpcep|lispflowmapping|snmp4sdn|\
yangtools.model.(ietf-ted-2013|ietf-topology-isis-2013|ietf-topology-2013|\
ietf-topology-l3-unicast-igp-2013|ietf-topology-ospf-2013)"

    bundlefilter="-bundlefilter org.opendaylight.(${filter})"
    exec /usr/share/opendaylight-controller/run.base.sh $bundlefilter "$@"
    ;;

virt-affinity)
    echo "$option not supported yet"
    filter="controller.samples|\
vtn|opendove|\
bgpcep|lispflowmapping|snmp4sdn|\
yangtools.model.(ietf-ted-2013|ietf-topology-isis-2013|ietf-topology-2013|\
ietf-topology-l3-unicast-igp-2013|ietf-topology-ospf-2013)"

    bundlefilter="-bundlefilter org.opendaylight.(${filter})"
    exec /usr/share/opendaylight-controller/run.base.sh $bundlefilter "$@"
    ;;

sp)
    echo "$option not supported yet"
    filter="opendove|ovsdb.ovsdb.neutron|vtn"

    bundlefilter="-bundlefilter org.opendaylight.(${filter})"
    exec /usr/share/opendaylight-controller/run.base.sh $bundlefilter "$@"
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
