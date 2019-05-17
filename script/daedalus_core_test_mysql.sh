#!/bin/bash

MYSQL_HOST=$1
MYSQL_USER=$2
MYSQL_PASSWORD=$3
SLEEP=$4
ATTEMPTS=$5

counter=0

while [[ $counter < $ATTEMPTS ]]
do
    mysqladmin  ping -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -P 3306 > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        break
    fi
    let "counter++"
    sleep $SLEEP
done

if [[ $counter == $ATTEMPTS ]]; then
    exit 1
fi
exit 0
