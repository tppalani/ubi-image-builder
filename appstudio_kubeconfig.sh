
RED='\033[0;31m'
NC='\033[0m' # No Color

NAMESPACE=$1

if [ -z "$1" ]; then
    echo "${RED}Please provide your namespace as argument to the command: '$0 <your_namespace>'\n"
    exit 1
fi

if ! command kubectl konfig &> /dev/null; then
 echo "konfig could not be found. Please install it: https://github.com/corneliusweig/konfig"
 exit 1
fi

if ! command -v kubectl &> /dev/null; then
  echo "kubectl could not be found. Please install it: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
  exit 1
fi

cat <<EOF > appstudio.cfg
apiVersion: v1
clusters:
- cluster:
    server: https://api-toolchain-host-operator.apps.stone-prd-host1.wdlc.p1.openshiftapps.com/workspaces/$NAMESPACE
  name: appstudio-$NAMESPACE
contexts:
- context:
    cluster: appstudio-$NAMESPACE
    namespace: $NAMESPACE-tenant
    user: oidc
  name: appstudio-$NAMESPACE
current-context: appstudio-$NAMESPACE
kind: Config
preferences: {}
users:
- name: oidc
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - oidc-login
      - get-token
      - --oidc-issuer-url=https://sso.redhat.com/auth/realms/redhat-external
      - --oidc-client-id=rhoas-cli-prod
      command: kubectl
      env: null
      interactiveMode: IfAvailable
      provideClusterInfo: false
EOF

#cat appstudio.cfg
kubectl konfig import --save appstudio.cfg
kubectl ctx appstudio-$NAMESPACE
