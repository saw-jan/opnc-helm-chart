# Openproject-Nextcloud Integration Helm Chart

## Prerequisites

- Kubernetes cluster (minikube)
- Helm
- kubectl
- Docker

## Deployment Steps

1. Start the Kubernetes cluster:
   ```bash
   minikube start
   ```
2. Enable the Ingress addon:

   ```bash
   minikube addons enable ingress
   ```

3. Install cert-manager CRDs and controller:

   ```bash
   # add repository
   helm repo add jetstack https://charts.jetstack.io

   # install cert-manager
   helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.18.0 \
    --set crds.enabled=true
   ```

4. Install integration helm chart:

   ```bash
   helm install opnc .
   ```

5. Check the pods:

   ```bash
   kubectl get pods
   ```

6. Add these hosts to your `/etc/hosts` file:
   ```
    sudo echo "$(minikube ip) openproject.local nextcloud.local keycloak.local" | sudo tee -a /etc/hosts
   ```

### Using local source code

In order to mount the local source code to the pods, we have to mount the local directory containing the required folders to the minikube first. And then we can reference that mounted directory in the pod specification.

**NOTE:** The source code needs to be compiled/built beforehand. It's tricky to build the project inside the pod due to varios constraints like permissions and missing dependencies.

1. Mount the local source code directory to minikube:

   ```bash
   minikube mount /path/to/your/local/dir:/localDir
   ```

2. Update the `values.yaml` file to reference the mounted directory:

   ```yaml
   openproject:
     localSrcPath: /localDir/openproject
   ```

3. Redeploy the helm chart:

   ```bash
   helm upgrade --install opnc .
   ```

### Useful Commands

- To see the pod logs:
  ```bash
  kubectl logs -f -l app=openproject
  ```
- To see the pod details (useful if the container is not starting):
  ```bash
  kubectl describe pod -l app=openproject
  ```
