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

### Using different versions

Currently, we can define the required versions for the following components:

```
1. integration_openproject app
2. OpenProject
3. Nextcloud
```

Please refer to [values.yaml](values.yaml) for available configuration options.

Use the following command to upgrade the release:

```bash
helm upgrade opnc .
```

or (if you have separate `values.yaml` file):

```bash
helm upgrade -f <path-to-values.yaml> <path-to-opnc-repo>
```

or (set the versions directly while running the command):

```bash
helm upgrade \
   --set nextcloud.integrationAppVersion=2.9.1 \
   opnc .
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
