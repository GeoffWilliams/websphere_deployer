#! /usr/bin/bash

if [[ $# != 1 ]]
then
        echo "Usage: $0 <appserver name>"
        exit 0
fi

. /opt/ibm/scripts/wasenv.sh

wascmddir=$(find $WASNODES -name $1 | sed 's/^\(.*\/AppSrv[0-9a-zA-Z]*..\)\/.*$/\1\/bin/')

if [[ -z $wascmddir ]]
then
	echo "Unable to find app server $1"
	exit 0
fi

$wascmddir/startServer.sh $1

exit $?
