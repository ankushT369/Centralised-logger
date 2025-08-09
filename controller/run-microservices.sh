#!/bin/bash
# Launch all 4 microservices in background, silently

FILE="/home/ankush/projects/centralised-logging/microservices/microservices.py"

echo "Running microservices..."
nohup python3 -u "$FILE" m1 > m1.log 2>&1 &
nohup python3 -u "$FILE" m2 > m2.log 2>&1 &
nohup python3 -u "$FILE" m3 > m3.log 2>&1 &
nohup python3 -u "$FILE" m4 > m4.log 2>&1 &
