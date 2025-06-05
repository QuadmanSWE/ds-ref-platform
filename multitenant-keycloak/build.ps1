push-location multitenant-keycloak

# pulls idp wizard, copies jarfile out to plugins
7z.exe a "plugins/io.phasetwo-phasetwo-idp-wizard-0.23.jar" "theme\wizard\login\wizard.ftl"

$registryName = 'docker.io'
$registryFqdn = $registryName
$repo = 'dsoderlund/keycloak-multitenant'
$newtag = get-date -format "yyyyMMddTHHmmss" #'20250513T151000'
$appversion = "26.2.5"

$localtag = "$repo`:$newtag"
$remotetag = "$registryFqdn/$localtag"

docker build -t $localtag --build-arg APP_SOURCE_REPO=quay.io/phasetwo/phasetwo-keycloak --build-arg APP_VERSION=$appversion .

# push to kind
# kind load docker-image -n ds-ref-cluster $localtag

# ready for rock and roll
docker login 

docker tag $localtag $remoteTag
docker push $remoteTag
docker push "$registryFqdn/$repo`:latest"

