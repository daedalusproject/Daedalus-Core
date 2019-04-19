#!/bin/bash

REDIS_HOST=$1
SLEEP=$2
ATTEMPTS=$3

counter=0

while [[ $counter < $ATTEMPTS ]]
do
    redis-cli -h $REDIS_HOST ping
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
