#!/bin/bash

set -eo pipefail

CURL=$(which curl)
if [ -z "$CURL" ]; then
    echo "[ERROR] curl: command not found"
    exit 1
fi

KC_URL="http://localhost:8080"

NC_CLIENT_DB_ID=d97b00f4-c4eb-41f0-ad9e-0c6674d13348
OP_CLIENT_DB_ID=2a721a37-e840-49d1-8715-ab36cfc56dcf
APIV3_SCOPE_ID=83625306-1925-4069-a77b-d8d9d2ec520b

###################################
# Start Keycloak                  #
###################################
/opt/bitnami/keycloak/bin/kc.sh start-dev --proxy-headers xforwarded \
    --spi-connections-http-client-default-disable-trust-manager=true &
KC_PID=$!

# wait for Keycloak to start
max_retry=60
retry=1
time_elapsed=0
# pre-wait to allow Keycloak to start
echo "[INFO] Waiting for Keycloak to be ready..."
sleep 10
while [[ $retry -le $max_retry ]]; do
    server_status=$($CURL -s -o /dev/null -w "%{http_code}" "$KC_URL" || echo "000")
    if [[ $server_status -ne 0 && $server_status -lt 400 ]]; then
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

# get access token for Keycloak admin
TOKEN=$($CURL -s -XPOST "$KC_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=admin-cli" \
    -d "username=$KC_BOOTSTRAP_ADMIN_USERNAME" \
    -d "password=$KC_BOOTSTRAP_ADMIN_PASSWORD" \
    -d "grant_type=password" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

if [ -z "$TOKEN" ]; then
    echo "[ERROR] Failed to obtain access token"
    exit 1
fi

# create realm with users and clients
COMMON_USER_ATTRIBUTES='
"emailVerified": true,
"enabled": true,
"credentials": [
    {
        "type": "password",
        "value": "1234",
        "temporary": false
    }
]'

COMMON_CLIENT_ATTRIBUTES='
"clientAuthenticatorType" : "client-secret",
"protocol": "openid-connect",
"enabled": true,
"attributes": {
    "standard.token.exchange.enableRefreshRequestedTokenType" : "SAME_SESSION",
    "standard.token.exchange.enabled" : "true"
}'

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
                '"$COMMON_USER_ATTRIBUTES"'
            },
            {
                "username": "brian",
                "firstName" : "Brian",
                "lastName" : "Murphy",
                "email" : "brian@example.com",
                '"$COMMON_USER_ATTRIBUTES"'
            }
        ],
        "clients": [
            {
                "id": "'"$NC_CLIENT_DB_ID"'",
                "clientId": "'"$KC_NEXTCLOUD_CLIENT_ID"'",
                "secret" : "'"$KC_NEXTCLOUD_CLIENT_SECRET"'",
                "redirectUris" : [ "https://'"$KC_NEXTCLOUD_CLIENT_HOST"'/*" ],
                '"$COMMON_CLIENT_ATTRIBUTES"'
            },
            {
                "id": "'"$OP_CLIENT_DB_ID"'",
                "clientId": "'"$KC_OPENPROJECT_CLIENT_ID"'",
                "secret" : "'"$KC_OPENPROJECT_CLIENT_SECRET"'",
                "redirectUris" : [ "https://'"$KC_OPENPROJECT_CLIENT_HOST"'/*" ],
                '"$COMMON_CLIENT_ATTRIBUTES"'
            }
        ]
    }'
)

if [[ "$realm_status" -ne 201 && "$realm_status" -ne 409 ]]; then
    echo "[ERROR] Failed to create realm '$KC_REALM_NAME', status code: $realm_status"
    exit 1
elif [[ "$realm_status" -ne 409 ]]; then
    echo "[INFO] Realm '$KC_REALM_NAME' exists, skipping creation..."
else
    echo "[INFO] Realm '$KC_REALM_NAME' created successfully"
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
elif [[ "$add_scope_status" -ne 409 ]]; then
    echo "[INFO] Client scope 'api_v3' exists, skipping creation..."
else
    echo "[INFO] Client scope 'api_v3' created successfully"
fi

# add api_v3 scope to the clients
for client_id in "$NC_CLIENT_DB_ID" "$OP_CLIENT_DB_ID"; do
    client_scope_status=$(
        $CURL -XPUT "$KC_URL/admin/realms/$KC_REALM_NAME/clients/$client_id/optional-client-scopes/$APIV3_SCOPE_ID" \
            -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $TOKEN"
    )

    if [ "$client_scope_status" -ne 204 ]; then
        echo "[ERROR] Failed to add scope 'api_v3' to client '$client_id', status code: $client_scope_status"
        exit 1
    else
        echo "[INFO] Scope 'api_v3' added to client '$client_id' successfully"
    fi
done

# bring Keycloak to foreground
wait $KC_PID
