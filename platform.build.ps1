param (
    $dnsname = "platform.local"
)

task cert_up {
    if(get-item 0_certs/root-ca -ea 0) {
        throw "Root CA already exists"
    }
    else {   
        # create a git ignored directory to store the root CA certificate and private key
        mkdir 0_certs/root-ca | out-null
        # create a new private key for the root CA
        openssl genrsa -out ./0_certs/root-ca/root-ca-key.pem 2048 | out-null
        # create a self-signed root CA certificate using the private key
        openssl req -x509 -new -nodes -key ./0_certs/root-ca/root-ca-key.pem -days 3650 -sha256 -out ./0_certs/root-ca/root-ca.pem -subj "/CN=kube-ca" | out-null
        # Copy the cert over to argocd app so that its kustomize can reference it for oidc
        mkdir ./2_platform/argocd/secrets
        cp 0_certs/root-ca/root-ca.pem ./2_platform/argocd/secrets/root-ca.pem
        # import the root CA certificate into the local machine's trusted root certificate store
        Import-Certificate -FilePath "./0_certs/root-ca/root-ca.pem" -CertStoreLocation cert:\CurrentUser\Root
    }
}

task cluster_up {
    ctlptl apply -f 1_cluster/kind/cluster.yaml
}
task cluster_down {
    ctlptl delete -f 1_cluster/kind/cluster.yaml
}
task platform_up {
    push-location 2_platform
    tilt up 
    pop-location
}
task platform_down {
    push-location 2_platform
    tilt down 
    pop-location
}
task backstage_up {
    
}
task backstage_down {
    
}
task apps_up {
    push-location 3_gitops
    tilt up 
    pop-location
}
task apps_down {
    push-location 3_gitops
    tilt down 
    pop-location
}
task local_dns {
    write-host "copy and paste into your host files (need to save as admin)"
@"
############################################
127.0.0.1 backstage.$dnsname
127.0.0.1 kc.$dnsname
127.0.0.1 argocd.$dnsname
127.0.0.1 pg.$dnsname
127.0.0.1 echo.$dnsname
127.0.0.1 argocd.$dnsname
############################################
"@ | write-host
    code c:\windows\system32\drivers\etc\hosts
}
task init cert_up, local_dns
task up cluster_up, apps_up, backstage_up
task down cluster_down