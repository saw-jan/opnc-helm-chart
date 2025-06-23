#!/bin/bash

rm -rf /etc/ssl/certs/OPNC_Root_CA.pem /usr/local/share/ca-certificates/OPNC_Root_CA.crt
cp /certs/ca.crt /usr/local/share/ca-certificates/OPNC_Root_CA.crt
update-ca-certificates

./docker/prod/entrypoint.sh ./docker/prod/supervisord
