#!/bin/bash

set -e

occ security:certificates:import /etc/ssl/certs/ca-certificates.crt
# setup user_oidc app
occ config:app:set --value=1 user_oidc store_login_token
occ config:system:set user_oidc --type boolean --value="true" oidc_provider_bearer_validation
occ user_oidc:provider Keycloak \
    -c 'nextcloud' \
    -s 'RGF6WCCOzm2bmnqgRelaIA5fp3XaMTIH' \
    -d 'https://keycloak.local/realms/opnc/.well-known/openid-configuration' \
    -o 'openid profile email api_v3'
