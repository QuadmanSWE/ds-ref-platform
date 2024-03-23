By having the crossplane provider as an application through gitops we can control the dependencies on CRDs in a way that tilt isn't really built for.

To do it we use sync-waves.

First the credentials that crossplane will use to connect to keycloak will show up.

![current mood](./docs/assets/2024-03-23-21-25-03.png)

Then we create the provider and wait for it to finish before we sync the provider configuration (which is dependent on the provider setting up its CRD)

To make sure that argocd doesn't fail during dryrun of all resources for missing CRDs we also need to add the annotation `argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true`

![](./docs/assets/2024-03-23-21-37-15.png)
