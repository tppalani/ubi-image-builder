# ubi-image-builder

Paketo GitHub flows to build the:
- Builder image: https://github.com/paketo-community/builder-ubi-base
- Buildpacks: https://github.com/paketo-buildpacks/pipeline-builder/tree/release-2.x/.github/workflows

## Pre-requisites

- Have an account and access to: https://console.redhat.com/preview/application-pipeline/
- Be part of the workspace `rh-biodlpacks`. See: https://console.redhat.com/preview/application-pipeline/access/workspaces/rh-buildpacks
- Kubectl, Tekton installed & [Tekton client](https://tekton.dev/docs/cli/)
- [krew](https://krew.sigs.k8s.io/), [oidc login](https://github.com/int128/kubelogin), [konfig](https://github.com/corneliusweig/konfig) & [ctx](https://github.com/ahmetb/kubectx)

## Instructions

To access remotely to the AppStudio cluster where the buildpacks image builder builds are taking place, customize first your kubecfg file using the 
command: `./appstudio_kubeconfig rh-buildpacks`

**NOTE**: More information to use kubectl login and to log in to the cluster using OIDC are available [here](https://docs.google.com/document/d/1hFvQDH1H6MGNqTGfcZpyl2h8OIaynP8sokZohCS0Su0/edit#heading=h.bksi3q7km0i)

### Local tekton

Before to test the project on the AppStudio cluster, you can create locally a kind cluster, deploy Tekton and test it
```bash
curl -s -L "https://raw.githubusercontent.com/snowdrop/k8s-infra/main/kind/kind.sh" | bash -s install
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl wait deployment -n tekton-pipelines tekton-pipelines-controller --for condition=Available=True --timeout=90s
kubectl wait deployment -n tekton-pipelines tekton-pipelines-webhookubectl --for condition=Available=True --timeout=90s

kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
VM_IP=127.0.0.1                                                                                                       
kubectl create ingress tekton-ui -n tekton-pipelines --class=nginx --rule="tekton-ui.$VM_IP.nip.io/*=tekton-dashboard:9097"
```
When done, you can install the packubectl pipeline able to build thje builder image 
```bash
kubectl delete -f tekton; kubectl apply -f tekton;
tkn pipelinerun logs pack-build-builder-push-run -f
```

## Tips 

To convert GitHub flows into bash scripts, use this [export-to-bash](https://github.com/snowdrop/export-github-flows/blob/main/README.md) project and the command
    
```bash
GIT_DIR=$(pwd)
pushd /path/to/export-github-flows/
./scripts/export-jobs.sh $GIT_DIR/github/paketo-builder-flow.yaml > $GIT_DIR/github/paketo-builder-push-bash.txt
popd
```