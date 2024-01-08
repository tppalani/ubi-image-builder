# Home project of: ubi-image-builder

The goal of this project is to build the builder image using the Java and Node.js buildpacks released for the image ubi 8.
This is a first step toward to automate fully the process to release the needed images like the buildpacks and/or extensions.
To achieve this goal, it will be needed to transpose the existing GitHub workflows created by the Paketo community to different Tekton pipelines.

More information around the building mechanisms designed by Paketo are documented [here](https://docs.google.com/document/d/1D5J14phPzXIN4-QVMs4xMy8NPuqN72LTbq6Eu1E1PE4/edit)

Some flows are available from the following projects: 
- Builder image: https://github.com/paketo-community/builder-ubi-base
- Buildpacks: https://github.com/paketo-buildpacks/pipeline-builder/tree/release-2.x/.github/workflows

## Pre-requisites

- Have an account and access to: https://console.redhat.com/preview/application-pipeline/
- Be part of the workspace `rh-Buildpacks`. See: https://console.redhat.com/preview/application-pipeline/access/workspaces/rh-buildpacks
- Kubectl, Tekton installed & [Tekton client](https://tekton.dev/docs/cli/)
- [krew](https://krew.sigs.k8s.io/), [oidc login](https://github.com/int128/kubelogin), [konfig](https://github.com/corneliusweig/konfig) & [ctx](https://github.com/ahmetb/kubectx)

To access remotely to the `RHTAP AppStudio cluster`, add first to your `kubecfg` config file the cluster URL, context and OIDC's user using the 
following bash script: `./appstudio_kubeconfig rh-buildpacks`

**NOTE**: More information to log in to the cluster using OIDC is available [here](https://docs.google.com/document/d/1hFvQDH1H6MGNqTGfcZpyl2h8OIaynP8sokZohCS0Su0/edit#heading=h.bksi3q7km0i)

## Instructions

During the development of this project, you can either use a local kind cluster where Tekton has been deployed or use directly the `AppStudio cluster`.

**NOTE**: Some hacks will be needed ss some differences exist between the RHTAP Pipeline(Run) definition and the [pack-builder-image.yml](tekton%2Fpipeline%2Fpack-builder-image%2F0.1%2Fpack-builder-image.yml) for local tests

### Local tekton

To create a cluster and install Tekton, execute the following commands:
```bash
curl -s -L "https://raw.githubusercontent.com/snowdrop/k8s-infra/main/kind/kind.sh" | bash -s install --delete-kind-cluster                                   
curl -s -L "https://raw.githubusercontent.com/snowdrop/k8s-infra/main/kind/registry.sh" | bash -s install --registry-name kind-registry.local

kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl wait deployment -n tekton-pipelines tekton-pipelines-controller --for condition=Available=True --timeout=90s
kubectl wait deployment -n tekton-pipelines tekton-pipelines-webhookubectl --for condition=Available=True --timeout=90s

kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
VM_IP=127.0.0.1                                                                                                       
kubectl create ingress tekton-ui -n tekton-pipelines --class=nginx --rule="tekton-ui.$VM_IP.nip.io/*=tekton-dashboard:9097"

echo "Disabling the affinity-assistant to avoid the error: more than one PersistentVolumeClaim is bound to a TaskRun = pod"
kubectl patch cm feature-flags -n tekton-pipelines -p '{"data":{"disable-affinity-assistant":"true"}}'
```

### Install the Pipeline, tasks and resources

Remark: To write the ubi builder image to a registry (quay.io, etc) , it is needed to create a secret including your credentials
```bash
kubectl create secret docker-registry quay-creds \
  --docker-username="<REGISTRY_USERNAME>" \
  --docker-password="<REGISTRY_PASSWORD>" \
  --docker-server="quay.io"
```

When done, you can install the yaml resources like the `ubi pack builder` pipeline: 
```bash
kubectl delete -R -f tekton
kubectl apply -R -f tekton
tkn pipelinerun logs pack-build-builder-push-run -f
```

## Test if the ubi builder image created is working

```bash
mvn io.quarkus.platform:quarkus-maven-plugin:3.3.2:create \
  -DprojectGroupId=dev.snowdrop \
  -DprojectArtifactId=quarkus-hello \
  -DprojectVersion=1.0 \
  -Dextensions='resteasy-reactive,kubernetes,buildpack'

cd quarkus-hello

REGISTRY_HOST="kind-registry.local:5000"
docker pull quay.io/snowdrop/ubi-builder:latest
pack build ${REGISTRY_HOST}/quarkus-hello:1.0 \
     --builder quay.io/snowdrop/ubi-builder \
     --volume $HOME/.m2:/home/cnb/.m2:rw \
     --path .  
docker run -i --rm -p 8080:8080 kind-registry.local:5000/quarkus-hello:1.0
curl localhost:8080/hello # in a separate terminal
```

### Install kubevirt (optional)

```bash
export KUBEVIRT_VERSION=v1.1.0
export KUBEVIRT_CDI_VERSION=v1.58.0
export KUBEVIRT_COMMON_INSTANCETYPES_VERSION=v0.3.2
echo "Deploying KubeVirt"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"
kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true}}}}'

echo "Deploying KubeVirt containerized-data-importer"
kubectl apply -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${KUBEVIRT_CDI_VERSION}/cdi-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${KUBEVIRT_CDI_VERSION}/cdi-cr.yaml"

echo "Waiting for KubeVirt to be ready"
kubectl wait --for=condition=Available kubevirt kubevirt --namespace=kubevirt --timeout=5m
          
echo "Patch the StorageProfile to use the storageclass standard and give ReadWrite access"
kubectl patch --type merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteOnce"]}]}}' StorageProfile standard

echo "Grant more rights to the default serviceaccount to access Kubevirt & Kubevirt CDI"
kubectl create clusterrolebinding pod-kubevirt-viewer --clusterrole=kubevirt.io:view --serviceaccount=default:default
kubectl create clusterrolebinding cdi-kubevirt-viewer --clusterrole=cdi.kubevirt.io:view --serviceaccount=default:default

echo "Creating the kubernetes secret storing the public key"
kubectl create secret generic fedora-vm-ssh-key --from-file=key=$HOME/.ssh/id_rsa.pub     

echo "Creating a DataVolume using as registry image our customized Fedora Cloud OS packaging: podman, socat"
kubectl create ns vm-images
kubectl apply -n vm-images -f resources/0.1-quay-to-pvc-datavolume.yml

echo "Creating the Fedora VM hosting podman & socat and exposing it under port => <VM_IP>:2376"
kubectl apply -f resources/02-fedora-dev-virtualmachine.yml

echo "Get the VM IP to ssh into it (optional"
VM_IP=$(kubectl get vmi -o jsonpath='{.items[0].status.interfaces[0].ipAddress}')
```


## Tips 

To convert the GitHub flows into bash scripts, use this [export-to-bash](https://github.com/snowdrop/export-github-flows/blob/main/README.md) project and the command
    
```bash
GIT_DIR=$(pwd)
pushd /path/to/export-github-flows/
./scripts/export-jobs.sh $GIT_DIR/github/paketo-builder-flow.yaml > $GIT_DIR/github/paketo-builder-push-bash.txt
popd
```

New build: 5 !
