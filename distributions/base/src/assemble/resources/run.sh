#!/bin/bash

# Whatever executable basename we happen to be, lets replace it
# with run.internal.sh
RUNSH_BASENAME=`basename $0`
CONTROLLER_RUNSH=`echo $0|sed "s;$RUNSH_BASENAME;run.internal.sh;"`

OF_FILTER=

# Be extra careful to pass on usage from run.internal.sh, but add our 
# usage as well in the standard way
function usage {
    $CONTROLLER_RUNSH -help | sed 's/\[-help\]/\[-help\] \[-of13\] \[-bundlefilter \<bundlefilter\> \]/' | sed "s;$CONTROLLER_RUNSH;$0;"
    exit 1
}

OF13=0
BUNDLEFILTER=
while true ; do
    (( i += 1 ))
    case "${@:$i:1}" in
        -of13) OF13=1 ;;
	-bundlefilter) (( i += 1 )); BUNDLEFILTER="|${@:$i:1}";;
        -help) usage ;;
	"") break ;;
    esac
done

# OF Filter selection
OF_FILTER="org.opendaylight.(openflowplugin|openflowjava)"
if [ $OF13 -ne 0 ]; then
    OF_FILTER="org.opendaylight.controller.(thirdparty.org.openflow|protocol_plugins.openflow)"
fi

# Make sure we suck out our additional args so as to not confuse
# run.internal.sh
NEWARGS=`echo $@|sed 's/-of13//'|sed 's/-bundlefilter[ ]*[^ ]*//'`

# Build the filter string
FILTERBEGINING='^(?!'
FILTERENDING=').*'
FILTER=${FILTERBEGINING}${OF_FILTER}${BUNDLEFILTER}${FILTERENDING}

# Run the command
$CONTROLLER_RUNSH -Dfelix.fileinstall.filter="$FILTER" $NEWARGS 
