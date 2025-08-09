#!/bin/bash
# Ocshestrator.sh controls execution and cleanup of 
# the kafka and microservices running in the background

# Get run-time in minutes (from arg or user input)
TIME="${1:-}"

if [ -z "$TIME" ]; then
    read -p "Enter execution time (minutes): " TIME
fi

./start-kafka.sh
./run-microservices.sh

sleep $(( TIME * 60 ))

./cleanup.sh
