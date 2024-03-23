# uses curl to invoke the keycloak REST api for ArgoCD
# gets a token for the master realm
echo "Logging on as $KEYCLOAK_ADMIN in keycloak to bootstrap ArgoCD client and group..."
mastertoken=$(curl -k -g -d "client_id=admin-cli" -d "username=$KEYCLOAK_ADMIN" -d "password=$KEYCLOAK_ADMIN_PASSWORD" -d "grant_type=password" -d "client_secret=" "http://keycloak.platform:80/realms/master/protocol/openid-connect/token" | sed 's/.*access_token":"//g' | sed 's/".*//g');
# echo $mastertoken;

id="9d0a21a2-8a08-4202-b2cb-c590e23c90c2";
url="http://keycloak.platform:80/admin/realms/master";

# creates a new client scope named "groups" with a Token Mapper which will add the groups claim to the token when the client requests the groups scope.

curl -X POST -k -g "$url/client-scopes" \
-H "Authorization: Bearer $mastertoken" \
-H "Content-Type: application/json" \
--data-raw '
{
    "name": "groups",
    "protocol": "openid-connect",
    "attributes": {
        "include.in.token.scope": "true",
        "display.on.consent.screen": "true",
        "consent.screen.text": "Access to group membership",
        "gui.order": "0",
        "gui.clientId": "argocd",
        "gui.enabled": "true",
        "display.on.token": "true",
        "token.claim.name": "groups",
        "multivalued": "true",
        "claim.name": "groups",
        "jsonType.label": "String"
    },
    "protocolMappers": [
        {
            "name": "groups",
            "protocol": "openid-connect",
            "protocolMapper": "oidc-group-membership-mapper",
            "consentRequired": false,
            "config": {
                "full.path" : "false",
                "id.token.claim" : "true",
                "access.token.claim" : "true",
                "claim.name" : "groups",
                "userinfo.token.claim" : "true"
            }
        }
    ]
}
'

# creates a new client named "argocd"
# using a clientreprentation according to the documentation: https://www.keycloak.org/docs-api/23.0.1/rest-api/#ClientRepresentation

curl -X POST -k -g "$url/clients" \
-H "Authorization: Bearer $mastertoken" \
-H "Content-Type: application/json" \
--data-raw '
{
    "id": "'$id'",
    "protocol": "openid-connect",
    "clientId": "argocd",
    "name": "argocd",
    "secret":"hbeT0fKekzgT0fGPMYV6On9cRcSHiU8b",
    "description": "",
    "publicClient": false,
    "authorizationServicesEnabled": true,
    "serviceAccountsEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": false,
    "standardFlowEnabled": true,
    "frontchannelLogout": true,
    "attributes": {
        "saml_idp_initiated_sso_url_name": "",
        "oauth2.device.authorization.grant.enabled": false,
        "oidc.ciba.grant.enabled": false,
        "post.logout.redirect.uris": "+"
    },
    "alwaysDisplayInConsole": false,
    "rootUrl": "",
    "baseUrl": "",
    "redirectUris": [
        "http://localhost:8085/auth/callback",
        "https://argocd.platform.local/*"
    ],
    "defaultClientScopes": ["openid", "profile", "email", "groups"]
}
';

# creates a new group called argocd-admin and adds the user $KEYCLOAK_ADMIN to it according to the documentation: https://www.keycloak.org/docs-api/23.0.1/rest-api/#GroupRepresentation
kcadminuserid=$(curl -X GET -k -g "$url/users?userName=$KEYCLOAK_ADMIN" -H "Authorization: Bearer $mastertoken" | jq -r '.[].id');

curl -X POST -k -g "$url/groups" \
-H "Authorization: Bearer $mastertoken" \
-H "Content-Type: application/json" \
--data-raw '
{
    "name": "argocd-admin"
}
';

groupid=$(curl -X GET -k -g "$url/groups" -H "Authorization: Bearer $mastertoken" | jq -r '.[] | select(.name == "argocd-admin") | .id');

# adds the user $KEYCLOAK_ADMIN to the group argocd-admin
curl -X PUT -k -g "$url/users/$kcadminuserid/groups/$groupid" -H "Authorization: Bearer $mastertoken";