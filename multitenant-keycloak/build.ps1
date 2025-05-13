$registryName = 'docker.io'
$registryFqdn = $registryName
$repo = 'dsoderlund/keycloak-multitenant'
$newtag = '20250513T151000'
$appversion = "26.2.3"

$localtag = "$repo`:$newtag"

docker build -t $localtag --build-arg APP_SOURCE_REPO=quay.io/phasetwo/phasetwo-keycloak --build-arg APP_VERSION=$appversion .

# push to kind
kind load docker-image -n ds-ref-cluster $localtag

# ready for rock and roll
docker login 
foreach ($t in ($newtag, 'latest')) {
    $remoteTag = "$registryFqdn/$repo`:$t"
    docker tag $localtag $remoteTag
    docker push $remoteTag
}
