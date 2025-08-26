#!/bin/bash

# Waiting for service initialization
until /usr/local/openvpn_as/scripts/sacli status 2>/dev/null |grep -q '"api": "on"'
do
    sleep 2
done

echo "[INFO] Running default post-start script for OpenVPN Access Server..."
/usr/local/openvpn_as/scripts/sacli start
