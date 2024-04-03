cd .\telepresence-demo\
npm install

docker build -t tdemo:blue .
kind load docker-image tdemo:blue --name ds-ref-cluster

docker build -t tdemo:green .
kind load docker-image tdemo:green --name ds-ref-cluster

node --inspect server.js


t helm install
k label namespace dsd istio-injection=disabled --overwrite
kustomize build .\hello-k8s\ | kubectl.exe apply -f -


t intercept hello-dev --port 3000:80