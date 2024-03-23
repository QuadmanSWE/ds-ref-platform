# David Söderlunds Reference Platform

Try out identity and access management and gitops quickly.

## Ew, its all in windows or something?

Yes, I haven't switched to linux on my daily driver. There is a gap in the market for platform engineers who know windows well for consulting companies that run a lot of windows and enterprise software.

Please send me a PR with the entire setup natively on linux.

## OK, so what is it?

1. It lets you bootstrap a local kubernetes cluster with little prerequisites.

2. It lets you deploy resources for practicing platform engineering with little configuration.

3. It lets you onboard your git repo as a source of truth for applications and other infrastructure.


## Right, but what is in it?

### Kubernetes uses (so these are the actual prerequisites)

- kind (kubernetes in docker)
- ctlptl (cattle patrol?)
- kustomize
- helm

To be able to deploy anything of the platform you need tilt. It is used as a way to sync the desired state of the platform to your cluster and be able to troubleshoot and also develop new apps without rebuilding images.

### Platform contains

- istio (service mesh and routing, like if linkerd and traeffik had a baby)
- keycloak (identity and access management, local users management, federation, brokerage)
- oauth2proxy (can act as an api gateway, and lets us deploy apps in our platform that get single sign on and stuff for free)
- postgres (got to run those databases somewhere, you can switch this out easily but its here to not leave any gaps)
- argocd (gitops tool with a kick as ui, can sync desired state of any thing kubernetes native to one or more clusters)
- crossplane (turn your cluster in-side-out, why just use the best api and distributed storage ever invented to manage containers? Let's kubernetes be the control plane of anything)
- hello world app (...I'm not very good with frontend. It lets you experience developing on top of tilt with hot reload while in a kubernetes cluster)

## I don't need help setting up a local kubernetes cluster

Awesome, skip that step and move on to the platform resources. Let me know how you did it.

## I don't like that tool

Substitute your own! Share your experience.

## I don't need all of this

Ignore it or comment it out of the respective kustomization file and tiltfile to skip deploying it.

## Hey you are obviously missing tool_x

Yes, obviously. Nice catch, please send a PR that includes and explains it for everyone.

## roadmap

- kyverno
- kubevirt
- vault