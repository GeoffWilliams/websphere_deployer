#! /usr/bin/bash

if [[ $# != 1 ]]
then
        echo "Usage: $0 <appserver name>"
        exit 0
fi

appserver=$1

. /opt/ibm/scripts/wasenv.sh

wascmddir=$(find $WASNODES -name $appserver | sed 's/^\(.*\/AppSrv[0-9a-zA-Z]*..\)\/.*$/\1\/bin/')

if [[ -z $wascmddir ]]
then
	echo "Unable to find app server $appserver"
	exit 0
fi

procCount=$(/usr/ucb/ps -auxww | grep "java .* "$appserver | grep -v grep | wc -l)

if (( $procCount != 0 ))
then
    $wascmddir/stopServer.sh $appserver
    result=$?
else
    echo "$appserver already stopped"
    result=0
fi


exit $result
