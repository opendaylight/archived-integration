#!/bin/bash

CONTROLLER_RUNSH=`echo $0|sed "s;run.sh;run.internal.sh;"`
OF_FILTER=

function usage {
    $CONTROLLER_RUNSH -help | sed 's/\[-help\]/\[-help\] \[-of13\]/' | sed "s;$CONTROLLER_RUNSH;$0;"
    exit 1
}

OF13=0
while true ; do
    (( i += 1 ))
    case "${@:$i:1}" in
        -of13) OF13=1 ;;
        -help) usage ;;
	"") break ;;
    esac
done

# OF Filter selection
OF_FILTER="^(?!org.opendaylight.(openflowplugin|openflowjava)).*"
if [ $OF13 -ne 0 ]; then
    OF_FILTER="^(?!org.opendaylight.controller.(thirdparty.org.openflow|protocol_plugins.openflow)).*"
fi

NEWARGS=`echo $@|sed 's/-of13//'`

$CONTROLLER_RUNSH -Dfelix.fileinstall.filter="$OF_FILTER" $NEWARGS 
