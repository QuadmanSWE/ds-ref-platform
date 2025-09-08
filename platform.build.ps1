param (
    [string]$username,
    [string]$password,
    [string]$email
)
$dnsname = "platform.local"
task 0_cert_up cert_create, cert_copy, cert_import
task cert_create {
    if(-not (get-item 0_certs/root-ca -ea 0)) {
        Write-Debug 'creating cert dir'
        # create a git ignored directory to store the root CA certificate and private key
        New-Item -ItemType Directory -Path 0_certs/root-ca | out-null

        Write-Debug 'creating new certs'
        # create a new private key for the root CA
        openssl genrsa -out ./0_certs/root-ca/root-ca-key.pem 2048 | out-null
        # create a self-signed root CA certificate using the private key
        openssl req -x509 -new -nodes -key ./0_certs/root-ca/root-ca-key.pem -days 3650 -sha256 -out ./0_certs/root-ca/root-ca.pem -subj "/CN=kube-ca" | out-null
    }
}
task cert_copy {
    if(get-item 0_certs/root-ca -ea 0) {
        # Copy the cert over to argocd app so that its kustomize can reference it for oidc
        New-Item -ItemType Directory -Path 2_platform/argocd/secrets -Force
        Copy-Item 0_certs/root-ca/root-ca.pem ./2_platform/argocd/secrets/root-ca.pem
    }
}
task cert_import {
    # import the root CA certificate into the local machine's trusted root certificate store
    if($IsWindows) {
        Import-Certificate -FilePath 0_certs/root-ca/root-ca.pem -CertStoreLocation cert:\CurrentUser\Root
    }
    else {
        sudo trust anchor 0_certs/root-ca/root-ca.pem
        sudo update-ca-trust
    }
}

task 1_cluster_up {
    ctlptl apply -f 1_cluster/kind/cluster.yaml
}
task 1_cluster_down {
    ctlptl delete -f 1_cluster/kind/cluster.yaml
}
task 2_platform_up {
    push-location 2_platform
    tilt up 
    pop-location
}
task 2_platform_down {
    push-location 2_platform
    tilt down 
    pop-location
}
task 3_gitops_up {
    push-location 3_gitops
    tilt up 
    pop-location
}
task 3_gitops_down {
    push-location 3_gitops
    tilt down 
    pop-location
}
task local_dns {
    if($IsWindows)
    {$hostsfile = "c:\windows\system32\drivers\etc\hosts"}
    else {$hostsfile = "/etc/hosts"}
    write-host "copy and paste into your host files (need to save as admin)"
    @"
############################################
127.0.0.1 kc.$dnsname
127.0.0.1 argocd.$dnsname
127.0.0.1 pg.$dnsname
127.0.0.1 echo.$dnsname
############################################
"@ | write-host
    code $hostsfile
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
    if($username -eq ''){
        $username = Read-Host -Prompt "Enter a username for the platform"
    } 
    if($password -eq ''){
        $password = Read-Host -Prompt "Enter a password for your platform user" -MaskInput
    }
    if($email -eq '')  {
        $email = Read-Host -Prompt "Enter an email for your platform user"
    }

    Write-Output "Boostrapping user $username"
    $stupidCharacters = '`''"$'
    if($password -match "[$stupidCharacters]") {
        throw "Password cannot contain any of the following characters: $stupidCharacters (because I couldn't get the curl command to escape them :D)"
    }
    
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
        if ( Get-Command $req -ErrorAction SilentlyContinue) {
            Write-Host "$req found"
            continue
        }
        else {
            Write-Host "$req not found. Please install it and try again"
            if($IsWindows){
                $scoopInstalled = Get-Command scoop -ErrorAction SilentlyContinue
                if(-not $scoopInstalled) {
                    $installScoop = Read-Host -Prompt "Would you like to install scoop? (y/n)"
                    if($installScoop -eq "y") {
                        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
                        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
                        scoop bucket add tilt-dev https://github.com/tilt-dev/scoop-bucket
                    }
                    else {
                        break;
                    }
                }
                $installNowWithScoop = Read-Host -Prompt "Would you like to install $req with scoop now? (y/n)"
                if($installNowWithScoop -eq "y") {
                    scoop install $req
                }
            }
            else {
                # todo: linux users need help here.
            }
        }
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
task init prereqs, bootstrap, 0_cert_up, local_dns
task 0 0_cert_up
task 1 1_cluster_up
task 2 2_platform_up
task 3 3_gitops_up
task up 1_cluster_up, 3_gitops_up
task down 1_cluster_down