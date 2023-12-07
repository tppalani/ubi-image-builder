# ubi-image-builder

## Pre-requisites

- Have an account and access to: https://console.redhat.com/preview/application-pipeline/
- Be part of the workspace `rh-biodlpacks`. See: https://console.redhat.com/preview/application-pipeline/access/workspaces/rh-buildpacks
- Kubectl and Tekton installed
- [krew](https://krew.sigs.k8s.io/), [oidc login](https://github.com/int128/kubelogin), [konfig](https://github.com/corneliusweig/konfig) & [ctx](https://github.com/ahmetb/kubectx)

## Instructions

To access remotely to the AppStudio cluster where the buildpacks image builder builds are taking place, customize first your kubecfg file using the 
command: `./appstudio_kubeconfig rh-buildpacks`

**NOTE**: More information to use kubectl login and to log in to the cluster using OIDC are available [here](https://docs.google.com/document/d/1hFvQDH1H6MGNqTGfcZpyl2h8OIaynP8sokZohCS0Su0/edit#heading=h.bksi3q7km0i)

