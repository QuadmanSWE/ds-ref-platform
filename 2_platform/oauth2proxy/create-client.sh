# uses curl to invoke the keycloak REST api for oauth2proxy
# gets a token for the master realm
echo "Logging on as $KEYCLOAK_ADMIN in keycloak to bootstrap oauth2proxy client and roles"
mastertoken=$(curl -k -g -d "client_id=admin-cli" -d "username=$KEYCLOAK_ADMIN" -d "password=$KEYCLOAK_ADMIN_PASSWORD" -d "grant_type=password" -d "client_secret=" "http://keycloak.platform:80/realms/master/protocol/openid-connect/token" | sed 's/.*access_token":"//g' | sed 's/".*//g');
# echo $mastertoken;

id="df9239c7-211d-4524-834a-2eedc3dca6af";
url="http://keycloak.platform:80/admin/realms/master";
clienturl="$url/clients/$id";

# creates a new client named "oauth2proxy"
# using a clientreprentation according to the documetation: https://www.keycloak.org/docs-api/23.0.1/rest-api/#ClientRepresentation
# curl -X DELETE -k -g  "$url/clients/$id" -H "Authorization: Bearer $mastertoken" 

curl -X POST -k -g "http://keycloak.platform:80/admin/realms/master/clients" \
-H "Authorization: Bearer $mastertoken" \
-H "Content-Type: application/json" \
--data-raw '
{
    "id": "'$id'",
    "protocol": "openid-connect",
    "clientId": "oauth2proxy",
    "name": "oauth2proxy",
    "secret":"oqoVVhGECYJRPkJ5OrixYJ3tki5nRg53",
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
        "*"
    ]
}
';

# updates user ds to be active with valid email
daviduserid=$(curl -X GET -k -g "$url/users?userName=$KEYCLOAK_ADMIN" -H "Authorization: Bearer $mastertoken" | jq -r '.[].id')
curl -X PUT -k -g "$url/users/$daviduserid" \
-H "Authorization: Bearer $mastertoken" \
-H "Content-Type: application/json" \
--data-raw '
{
    "username":"ds",
    "enabled":"true",
    "emailVerified":"true",
    "firstName":"David",
    "lastName":"Söderlund",
    "email":"'$KEYCLOAK_ADMIN_EMAIL'"
}
'