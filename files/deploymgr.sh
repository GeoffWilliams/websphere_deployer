#! /usr/bin/bash
######################################################
# Environment
######################################################

BASE_DIR=/opt/ibm/deployments

DEPLOY_BIN=$BASE_DIR/bin
INCOMING=$BASE_DIR/incoming
PROCESSED=$BASE_DIR/processed
PROCESSING=$BASE_DIR/processing
PROPERTIES=$BASE_DIR/properties
ERROR=$BASE_DIR/error

. $DEPLOY_BIN/env.sh

RESTART_APPSERVER_CMD=/opt/ibm/scripts/restartAppServer.sh
STOP_APPSERVER_CMD=/opt/ibm/scripts/stopAppServer.sh
WGET_CMD=/usr/sfw/bin/wget

ENVJSP=/opt/ibm/etc/env.jsp

# WSADMIN_DIR array holding pre and post directory structure, two digit number sandwiched below
WSADMIN_DIR=(/opt/ibm/WebSphere/AppServer/profiles/Dmgr /bin/wsadmin.sh)

WASDEPLOY=/opt/ibm/scripts/was_deploy.py

PROCESSING_FLAG=$BASE_DIR/processing/active

EMAIL_RECIPIENT="ebusOpsSupport@rta.nsw.gov.au"
#EMAIL_RECIPIENT="nagababu.bonu@rms.nsw.gov.au"


######################################################
# Functions
######################################################

function printMessage {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

function sendEmail {
    se_type=$1
    se_file=$2
    se_message=$3
    se_additionalEmails=$4

    echo "From: $LOGNAME@$HOSTNAME" > /tmp/deploymgr_email.txt
    echo "To: $EMAIL_RECIPIENT" >> /tmp/deploymgr_email.txt
    echo "Cc: $additionalEmails" >> /tmp/deploymgr_email.txt
    echo "Subject: WAS deployment $se_type: $se_file on $HOSTNAME" >> /tmp/deploymgr_email.txt
    echo "${se_message:-No errors reported}" >> /tmp/deploymgr_email.txt

    ccList=""
        if [[ -n $additionalEmails ]]
    then
        ccList="Cc:$additionalEmails"
    fi

    mail To:$EMAIL_RECIPIENT $ccList < /tmp/deploymgr_email.txt

}

function sendCompletionEmail {
    sce_type="complete"
    sce_file=$1
    sce_message=$2
    sce_additionalEmails=$3

    sendEmail "$sce_type" "$sce_file" "$sce_message" "$sce_additionalEmails"
}

function sendStartEmail {
    sse_type="starting"
    sse_file=$1
    sse_message=$2
    sse_additionalEmails=$3

    sendEmail "$sse_type" "$sse_file" "$sse_message" "$sse_additionalEmails"
}

function getAttribute {
    ga_attributeName=$1
    ga_propertiesFile=$2

    echo $(grep -i "^$ga_attributeName" "$ga_propertiesFile" | sed 's/^.*\=\(.*\)$/\1/')
}

function processWGET {
    pw_file=$1

    pw_earfile=${pw_file%%.wget}.ear

    printMessage "Retrieving $(<$pw_file)"

    $WGET_CMD $(<$pw_file) -q -O $pw_earfile

    if [[ $? == 0 ]]
    then
        printMessage "Successfully retrieved ${pw_earfile##*/}"
        printMessage "Moving ${pw_file##*/} to $PROCESSED"
        mv $pw_file $PROCESSED
    else
        printMessage "Error retrieving ${pw_earfile##*/}"
        rm $pw_earfile 2>/dev/null
        #printMessage "Moving ${pw_file##*/} to $ERROR"
        #mv $pw_file $ERROR
        errorMsg="Error retrieving from wget location"
    fi
}

function finishProcessing {

    fp_file=$1
    fp_errorMsg=$2

    fp_baseFile=${fp_file##*/}

    if [[ -n $fp_errorMsg ]]
    then
        printMessage $fp_errorMsg
        printMessage "Moving $fp_baseFile to error directory"
        mv "$fp_file" "$ERROR"
    else
        printMessage "Moving $fp_baseFile to processed directory"
        mv "$fp_file" "$PROCESSED"
    fi

    printMessage "Sending confirmation email"

    sendCompletionEmail "$fp_baseFile" "$fp_errorMsg" "$additionalEmails"

    printMessage "=== Finished processing $fp_baseFile"

}

######################################################
# Main
######################################################


### Check for current processing

processingFlag=$(ls $PROCESSING_FLAG 2>/dev/null)

if [[ -n $processingFlag ]]
then
    printMessage "Stopping next batch invocation - deployment(s) in progress"
    exit
fi

### Look for files to process

declare -a incomingFiles=($(ls $INCOMING/*.ear $INCOMING/*.wget 2>/dev/null))

if [[ ${#incomingFiles[*]} > 0 ]]
then
    touch $PROCESSING_FLAG
    printMessage "+++ Batch START"
    printMessage "Found file(s) ${incomingFiles[*]##*/}"
else
    exit 
fi

### Move files to process to processing directory

mv ${incomingFiles[*]} $PROCESSING

# execute deployments

errorMsg=""
additionalEmails=""

declare -a processingFiles=($(ls $PROCESSING/*.ear $PROCESSING/*.wget 2>/dev/null))


for file in ${processingFiles[*]}
do
    baseFile=${file##*/}
    currentFile=$file

    printMessage "=== Processing $baseFile"

    # get file extension
    ext=${baseFile##*.}

    propertiesFile=$PROPERTIES/${baseFile%*.$ext}.properties

    if [[ ! -a $propertiesFile ]]
    then 
        finishProcessing $currentFile "Property file $propertiesFile does not exist"
        continue
    fi

    printMessage "Found properties file $propertiesFile"

    # deployment warning email

    additionalEmails=$(getAttribute "additionalEmails" "$propertiesFile")

    printMessage "Sending start email"

    sendStartEmail "$baseFile" " " "$additionalEmails"

    # convert wget to an ear
    if [[ $ext == "wget" ]]
    then
        processWGET $currentFile
    fi

    if [[ "$errorMsg" != "" ]]
    then
        finishProcessing $currentFile "$errorMsg"
        errorMsg=""
        continue
    fi 

    # if wget path convert file and baseFile to the ear equivalent
    if [[ $ext == "wget" ]]
    then
        currentFile=${currentFile%*.wget}.ear
        baseFile=${baseFile%*.wget}.ear
    fi

    # Retrieve affected app servers
    appServers=$(getAttribute "appServers" "$propertiesFile")

    if [[ -z "$appServers" ]]
    then
        finishProcessing $currentFile "Missing app server information"
        continue
    fi

    # Retrieve affected dmgr cells 
    dmgr=$(getAttribute "cell" "$propertiesFile")

    if [[ -z "$dmgr" ]]
    then
        finishProcessing $currentFile "Missing cell information"
        continue
    fi

    # stop appservers 
    stopAppServers=$(getAttribute "stopAppServers" "$propertiesFile")

    if [[ "$stopAppServers" != "False" ]]
    then
        printMessage "Stopping app server(s) $appServers"

        #+++ 
        $STOP_APPSERVER_CMD $appServers
    else
        printMessage "App server(s) stop skipped"
    fi

    printMessage "printing cell information $dmgr"
    printMessage "Running application deployment script"

    #+++	
    # Construct WSADMIN_CMD from pre and post dir strings and sandwich Cell number
    WSADMIN_CMD=${WSADMIN_DIR[0]}${dmgr#*Cell}${WSADMIN_DIR[1]}
    $WSADMIN_CMD -lang jython -f $WASDEPLOY $propertiesFile 

    if [[ $? != 0 ]]
    then
        finishProcessing $currentFile "jython deploy script failed"
        continue
    fi

    # Restart App Server

    restartAppServers=$(getAttribute "restartAppServers" "$propertiesFile")

    if [[ "$restartAppServers" != "False" ]]
    then
        # restart application servers (assume just one for now)
        printMessage "Restarting app server(s) $appServers"

        #+++
        $RESTART_APPSERVER_CMD $appServers
    else
        printMessage "App server(s) restart skipped"
    fi

    # Deploy env.jsp

    deployEnvJSP=$(getAttribute "deployEnvJSP" "$propertiesFile")

    if [[ "$deployEnvJSP" != "False" ]]
    then
        printMessage "Finding destination for env.jsp"

        appName=$(getAttribute "appName" "$propertiesFile")

        envLocation="$(find $INSTALLEDAPPS -type d -name WEB-INF 2>/dev/null | grep "/${appName}.ear/" | tail -1)"

        if [[ -z "$envLocation" ]]
        then
            finishProcessing $currentFile "Unable to find env.jsp destination"
            continue
        fi

        finalLocation="${envLocation}/.."

	printMessage "Installing env.jsp in $finalLocation"

	#+++
	cp "$ENVJSP" "$finalLocation"
    else
        printMessage "env.jsp deployment skipped"
    fi

    finishProcessing $currentFile 
done

#Allow next run of this batch to process files

rm $PROCESSING_FLAG

printMessage "+++ Batch FINISH"

