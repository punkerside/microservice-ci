#!/bin/bash

NUM=0

while [ "$(curl -s -o /dev/null -w '%{http_code}' localhost:3000/api)" != "200" ]
do
    if [ ${NUM} -gt 15 ]
    then
        break
    fi
    NUM=`expr $NUM + 1`
    sleep 2
done
