# uses curl to invoke the keycloak REST api
# gets a token for the master realm
mastertoken=$(curl -k -g -d "client_id=admin-cli" -d "username=ds" -d "password=UsrmxwawnVTgEjRqm3H0" -d "grant_type=password" -d "client_secret=" "http://keycloak.platform:80/realms/master/protocol/openid-connect/token" | sed 's/.*access_token":"//g' | sed 's/".*//g')

id="e7276799-95ce-4352-b654-587ca0fa2dba"
url="http://keycloak.platform:80/admin/realms/master"
clienturl="$url/clients/$id"

# creates a new client named "backstage"
# using a clientreprentation according to the documetation: https://www.keycloak.org/docs-api/23.0.1/rest-api/#ClientRepresentation

curl -X POST -k -g "$url/clients" \
-H "Authorization: Bearer $mastertoken" \
-H "Content-Type: application/json" \
--data-raw '
{
  "id":"'$id'",
  "name":"backstage",
  "clientId":"backstage",
  "secret":"oqoVVhGECYJRPkJ5OrixYJ3tki5nRg53",
  "clientAuthenticatorType":"client-secret",
  "serviceAccountsEnabled":"true",
  "standardFlowEnabled":"false"
}'

# GETs the service-account-user for the client - GET $url/clients/{id}/service-account-user
userid=$(curl -X GET -k -g "$clienturl/service-account-user" -H "Authorization: Bearer $mastertoken"  | sed 's/.*id":"//g' | sed 's/".*//g')
# echo $userid
# gets the user info
# curl -X GET -k -g -H "Authorization: Bearer $mastertoken" "$url/users/$userid"

# Gets the clientid of the master-realm so that we can add the roles to the service account user
clientid=$(curl -X GET -k -g -H "Authorization: Bearer $mastertoken" "$url/clients?clientId=master-realm"  | sed 's/.*id":"//g' | sed 's/".*//g')
# echo $clientid

# lists available roles
roles=$(curl -X GET -k -g -H "Authorization: Bearer $mastertoken" "$url/clients/$clientid/roles")
# echo $roles

view_users_id=$(echo $roles | jq -r '.[] | select(.name == "view-users") | .id')
query_groups_id=$(echo $roles | jq -r '.[] | select(.name == "query-groups") | .id')
query_users_id=$(echo $roles | jq -r '.[] | select(.name == "query-users") | .id')

# echo $view_users_id; echo $query_groups_id; echo $query_users_id

# adds service account roles query-users, view-users and view-groups to the client's user 
curl -X POST -k -g "$url/users/$userid/role-mappings/clients/$clientid" \
-H "Authorization: Bearer $mastertoken" \
-H "Content-Type: application/json" \
--data-raw '[
{
    "id":"'$query_users_id'",
    "name":"query-users"
},
{
    "id":"'$view_users_id'",
    "name":"view-users"
},
{
    "id":"'$query_groups_id'",
    "name":"query-groups"
}
]'
