$registryName = 'docker.io'
$registryFqdn = $registryName
$repo = 'dsoderlund/keycloak-multitenant'
$tag = 'latest'

$localtag = "$repo`:$tag"
$remotetag = "$registryFqdn/$localtag"

docker build -t $localtag --build-arg APP_SOURCE_REPO=quay.io/phasetwo/phasetwo-keycloak --build-arg APP_VERSION=26.0.2 .

# push to kind
kind load docker-image -n ds-ref-cluster $localtag
kind load docker-image -n ds-ref-cluster $remotetag

# ready for rock and roll
docker tag $localtag $remotetag
docker push $remotetag