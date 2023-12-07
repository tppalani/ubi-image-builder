# ubi-image-builder

Paketo GitHub flows to build the:
- Builder image: https://github.com/paketo-community/builder-ubi-base
- Buildpacks: https://github.com/paketo-buildpacks/pipeline-builder/tree/release-2.x/.github/workflows

## Pre-requisites

- Have an account and access to: https://console.redhat.com/preview/application-pipeline/
- Be part of the workspace `rh-biodlpacks`. See: https://console.redhat.com/preview/application-pipeline/access/workspaces/rh-buildpacks
- Kubectl and Tekton installed
- [krew](https://krew.sigs.k8s.io/), [oidc login](https://github.com/int128/kubelogin), [konfig](https://github.com/corneliusweig/konfig) & [ctx](https://github.com/ahmetb/kubectx)

## Instructions

To access remotely to the AppStudio cluster where the buildpacks image builder builds are taking place, customize first your kubecfg file using the 
command: `./appstudio_kubeconfig rh-buildpacks`

**NOTE**: More information to use kubectl login and to log in to the cluster using OIDC are available [here](https://docs.google.com/document/d/1hFvQDH1H6MGNqTGfcZpyl2h8OIaynP8sokZohCS0Su0/edit#heading=h.bksi3q7km0i)

To convert github flows into bash scripts, use this [export-to-bash](https://github.com/snowdrop/export-github-flows/blob/main/README.md) project and the command
    
```bash
GIT_DIR=$(pwd)
pushd /path/to/export-github-flows/
./scripts/export-jobs.sh $GIT_DIR/github/paketo-builder-flow.yaml > $GIT_DIR/github/paketo-builder-push-bash.txt
popd
```