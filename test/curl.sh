#!/bin/bash

LB_IP_ADDRESS=$(gcloud compute forwarding-rules list | grep go-echo-api | awk '{ print $2 }')
echo ${LB_IP_ADDRESS}

a=0
while [ "$a" -lt 100000 ]
do
    curl ${LB_IP_ADDRESS}
    sleep 0.1
done