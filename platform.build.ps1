param (
    $dnsname = "platform.local" #todo: this can be changed here but it won't work with any value but the default since its hardcoded everywhere.
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
        # Copy the cert over to argocd app so that its kustomize can reference it for oidc
        cp 0_certs/root-ca/root-ca.pem ./2_platform/argocd/secrets/root-ca.pem
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
task crossplane_up {
    push-location 4_crossplane
    tilt up
    pop-location
}
task crossplane_down {
    push-location 4_crossplane
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
############################################
"@ | write-host
    code c:\windows\system32\drivers\etc\hosts
}
task bootstrap {
    $kcadminpatchpattern = @"
- op: add
  path: /data/KEYCLOAK_ADMIN
  value: {0}
- op: add
  path: /data/KEYCLOAK_ADMIN_PASSWORD
  value: {1}
"@
    $kcauthpatchpattern = @"
- op: add
  path: /spec/template/spec/containers/0/env
  value:
    - name: KEYCLOAK_ADMIN
      value: {0}
    - name: KEYCLOAK_ADMIN_PASSWORD
      value: {1}
    - name: KEYCLOAK_ADMIN_EMAIL
      value: {2}
"@
    # Pick a username and a default password to use for the platform.
    $username = Read-Host -Prompt "Enter a username for the platform"
    $password = Read-Host -Prompt "Enter a password for your platform user" -MaskInput
    $stupidCharacters = '`''"$'
    if($password -match "[$stupidCharacters]") {
        throw "Password cannot contain any of the following characters: $stupidCharacters (because I couldn't get the curl command to escape them :D)"
    }
    $email = Read-Host -Prompt "Enter an email for your platform user"
    $kcadminpatchpattern -f $username, $password > 2_platform/keycloak/keycloak-admin-patch.yaml
    $kcauthpatchpattern -f $username, $password, $email  > 2_platform/keycloak-auth-patch.yaml
}
task prereqs {
    $reqs = @(
        "kubectl",
        "kind",
        "tilt",
        "ctlptl",
        "openssl",
        "helm",
        "kustomize"
    )
    foreach ($req in $reqs) {
        if (-not (Get-Command $req -ErrorAction SilentlyContinue)) {
            throw "$req is required but not found"
        }
        Write-Host "$req found"
    }
}
task changebranch {
    $mainbranch = 'main'
    $currentBranch = git rev-parse --abbrev-ref HEAD
    $filesToChange = Get-ChildItem -Recurse -Filter 'gitops-*.yaml'
    foreach ($file in $filesToChange) {
        $content = Get-Content $file
        if($content -match ": $mainbranch") {
            $content = $content -replace ": $mainbranch", ": $currentBranch"
        }
        else{
            $content = $content -replace ": $currentBranch", ": $mainbranch"
        }
        
        $content | Set-Content $file
    }
}
task cb changebranch
task dns_local local_dns
task init prereqs, bootstrap, cert_up, local_dns
task up cluster_up, crossplane_up
task down cluster_down