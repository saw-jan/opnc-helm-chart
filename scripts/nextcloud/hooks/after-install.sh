#!/bin/bash

set -eo pipefail

occ security:certificates:import /etc/ssl/certs/ca-certificates.crt
# setup user_oidc app
occ config:app:set --value=1 user_oidc store_login_token
occ config:system:set user_oidc --type boolean --value="true" oidc_provider_bearer_validation
occ user_oidc:provider:delete Keycloak -f
occ user_oidc:provider "$OIDC_KEYCLOAK_PROVIDER_NAME" \
    -c "$OIDC_KEYCLOAK_NEXTCLOUD_CLIENT_ID" \
    -s "$OIDC_KEYCLOAK_NEXTCLOUD_CLIENT_SECRET" \
    -d "$OIDC_KEYCLOAK_DISCOVERY_URL" \
    -o "openid profile email api_v3"
