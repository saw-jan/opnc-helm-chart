#!/bin/bash

set -eo pipefail

CURL="/shared/bin/curl"
JQ="/shared/bin/jq"

KC_URL="https://$KC_HOSTNAME"

NC_CLIENT_DB_ID=$(cat /proc/sys/kernel/random/uuid)
OP_CLIENT_DB_ID=$(cat /proc/sys/kernel/random/uuid)
APIV3_SCOPE_ID=$(cat /proc/sys/kernel/random/uuid)

###################################
# Start Keycloak                  #
###################################
/opt/keycloak/bin/kc.sh start-dev --proxy-headers xforwarded \
    --spi-connections-http-client-default-disable-trust-manager=true &

# wait for Keycloak to start
max_retry=60
retry=1
time_elapsed=0
# pre-wait to allow Keycloak to start
echo "[INFO] Waiting for Keycloak to be ready..."
sleep 5
while [[ $retry -le $max_retry ]]; do
    server_status=$($CURL -s -o /dev/null -w "%{http_code}" "$KC_URL")
    echo "[INFO] Waiting for Keycloak @ $$KC_URL: $server_status"
    if [[ $server_status -ne 000 && $server_status -lt 400 ]]; then
        break
    fi
    echo "[INFO] Waiting for Keycloak to be ready... (Retry $retry/$max_retry)"
    sleep 5
    time_elapsed=$((time_elapsed + 5))
    ((retry++))
done
if [[ $retry -gt $max_retry ]]; then
    echo "[ERROR] $time_elapsed seconds timeout. Keycloak is not ready"
    exit 1
fi

###################################
# Setup realm, users and clients  #
###################################
TOKEN=$($CURL -s -XPOST "$KC_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=admin-cli" \
    -d "username=$KC_BOOTSTRAP_ADMIN_USERNAME" \
    -d "password=$KC_BOOTSTRAP_ADMIN_PASSWORD" \
    -d "grant_type=password" | $JQ -r .access_token)

if [ -z "$TOKEN" ]; then
    echo "[ERROR] Failed to obtain access token"
    exit 1
fi

realm_status=$(
    $CURL -XPOST "$KC_URL/admin/realms" -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{ 
        "realm":"'"$KC_REALM_NAME"'",
        "enabled":true,
        "users": [
            {
                "username": "alice",
                "firstName" : "Alice",
                "lastName" : "Hansen",
                "email" : "alice@example.com",
                "emailVerified": true,
                "enabled": true,
                "credentials": [
                    {
                        "type": "password",
                        "value": "1234",
                        "temporary": false
                    }
                ]
            },
            {
                "username": "brian",
                "firstName" : "Brian",
                "lastName" : "Murphy",
                "email" : "brian@example.com",
                "emailVerified": true,
                "enabled": true,
                "credentials": [
                    {
                        "type": "password",
                        "value": "1234",
                        "temporary": false
                    }
                ]
            }
        ],
        "clients": [
            {
                "id": "'"$NC_CLIENT_DB_ID"'",
                "clientId": "'"$KC_NEXTCLOUD_CLIENT_ID"'",
                "secret" : "'"$KC_NEXTCLOUD_CLIENT_SECRET"'",
                "redirectUris" : [ "https://"'"$KC_NEXTCLOUD_CLIENT_HOST"'"/*" ],
                "clientAuthenticatorType" : "client-secret",
                "protocol": "openid-connect",
                "enabled": true,
                "attributes": {
                    "standard.token.exchange.enableRefreshRequestedTokenType" : "SAME_SESSION",
                    "standard.token.exchange.enabled" : "true"
                }
            },
            {
                "id": "'"$OP_CLIENT_DB_ID"'",
                "clientId": "'"$KC_OPENPROJECT_CLIENT_ID"'",
                "secret" : "'"$KC_OPENPROJECT_CLIENT_SECRET"'",
                "redirectUris" : [ "https://"'"$KC_OPENPROJECT_CLIENT_HOST"'"/*" ],
                "clientAuthenticatorType" : "client-secret",
                "protocol": "openid-connect",
                "enabled": true,
                "attributes": {
                    "standard.token.exchange.enableRefreshRequestedTokenType" : "SAME_SESSION",
                    "standard.token.exchange.enabled" : "true"
                }
            }
        ]
    }'
)

if [[ "$realm_status" -ne 201 && "$realm_status" -ne 409 ]]; then
    echo "[ERROR] Failed to create realm '$KC_REALM_NAME', status code: $realm_status"
    exit 1
fi

# create client scope: api_v3
add_scope_status=$(
    $CURL -XPOST "$KC_URL/admin/realms/$KC_REALM_NAME/client-scopes" \
        -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
        "id":"'"$APIV3_SCOPE_ID"'",
        "name":"api_v3",
        "protocol":"openid-connect",
        "attributes": {"include.in.token.scope":"true"},
        "protocolMappers": [
            {
                "name": "nc_aud_mapper",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-audience-mapper",
                "config": {
                    "included.client.audience": "'"$KC_NEXTCLOUD_CLIENT_ID"'",
                    "access.token.claim": "true"
                }
            },
            {
                "name": "op_aud_mapper",
                "protocol": "openid-connect",
                "protocolMapper": "oidc-audience-mapper",
                "config": {
                    "included.client.audience": "'"$KC_OPENPROJECT_CLIENT_ID"'",
                    "access.token.claim": "true"
                }
            }
        ]
    }'
)

if [[ "$add_scope_status" -ne 201 && "$add_scope_status" -ne 409 ]]; then
    echo "[ERROR] Failed to create client scope 'api_v3', status code: $add_scope_status"
    exit 1
fi

# add api_v3 scope to the clients
for client_id in $NC_CLIENT_DB_ID $OP_CLIENT_DB_ID; do
    client_scope_status=$($CURL -XPUT "$KC_URL/admin/realms/$KC_REALM_NAME/clients/$client_id/optional-client-scopes/$APIV3_SCOPE_ID" \
        -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN")

    if [ "$client_scope_status" -ne 204 ]; then
        echo "[ERROR] Failed to add scope 'api_v3' to client '$client_id', status code: $client_scope_status"
        exit 1
    fi
done
