#!/bin/bash
##############################################################################
# ZertoMySQLCheckpoint.sh
#
# Created by Justin Paul, Tech Alliances Architect, Zerto
# Contact at jp@zerto.com or on Twitter at @recklessop
#
# This script does the following:
# 1.) Lock all MySQL tables and flush data to disk.
# 2.) Call Zerto REST API and insert a User defined Checkpoint
# 3.) Unlock the MySQL tables and resume normal operations
#
# You must provide the VPGID for the VPG that needs the checkpoint inserted.
# To get this information
##############################################################################

##### Variables Replace with your information #####
ZVMIP="172.16.1.20"
ZVMPORT="9669"
ZVMUSER="administrator@vsphere.local"
ZVMPWD="mypassword"
VPGID="97b4b6be-5447-491b-bd10-be3600c91ff0"
MYSQLUSER="adminuser"
MYSQLPASSWORD="adminpassword"

##### Write Date Time to Log file #####

##### Login to Zerto REST API #####
curl -k -D responseHeader -H "Content-Type: application/json" -H "Accept: application/json" --user $ZVMUSER:$ZVMPWD https://${ZVMIP}:${ZVMPORT}/v1/session/add -d "{\"AuthenticationMethod\":0}"
COOKIE=`cat responseHeader | grep x-zerto-session`
SESSION=$(echo "$COOKIE"|tr -d '\r')
echo "---------------------------------" >> ZertoCheckpointInsert.log
echo $SESSION >> ZertoCheckpointInsert.log
echo "---------------------------------" >> ZertoCheckpointInsert.log

##### Lock and Flush MySQL Databases #####
outputLock=$(mysql --user="${MYSQLUSER}" --password="${MYSQLPASSWORD}" --execute=' flush tables with read lock;' 2>&1)
echo $outputLock >> ZertoCheckpointInsert.log

##### Insert Zerto User Checkpoint #####
INSERTOUTPUT=$(curl -k -H "${SESSION}" -H "Content-Type: application/json" -H "Accept: application/json" -X POST -d '{"checkpointName":"MySQL Quiesced Checkpoint"}' https://${ZVMIP}:${ZVMPORT}/v1/vpgs/"${VPGID}"/Checkpoints)
echo $responseHeader >> ZertoCheckpointInsert.log

##### Lock and Flush MySQL Databases #####
outputUnlock=$(mysql --user="${MYSQLUSER}" --password="${MYSQLPASSWORD}" --execute=' unlock tables;' 2>&1)
echo $outputUnlock >> ZertoCheckpointInsert.log

