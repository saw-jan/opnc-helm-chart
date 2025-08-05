# Openproject-Nextcloud Integration Helm Chart

- [Prerequisites](#prerequisites)
- [Deploy Setup](#deploy-setup)
- [Configuring the Setup](#configuring-the-setup)
- [Serve From Git Branch](#server-from-git-branch)
- [Trust Self-Signed Certificates](#trust-self-signed-certificates)

## Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download)
- [docker](https://docs.docker.com/engine/install/)
- [helm](https://helm.sh/docs/intro/install/#through-package-managers)
- [helm-diff](https://github.com/databus23/helm-diff?tab=readme-ov-file#using-helm-plugin-manager--23x) plugin
- [helmfile](https://helmfile.readthedocs.io/en/latest/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

## Deploy Setup

1. Start a Kubernetes cluster:
   ```bash
   minikube start
   ```
2. Enable ingress addon:

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

4. Deploy integration chart:

   ```bash
   helmfile apply
   ```

5. Check the pods:

   ```bash
   kubectl get pods
   ```

   NOTE: make sure at least one `setup-job-*` pod is completed successfully before proceeding.

   ```
   NAME                                          READY   STATUS      RESTARTS   AGE
   setup-job-5nwlm                               0/1     Error       0          17m
   setup-job-mkgrf                               0/1     Completed   0          12m
   ```

6. Add these hosts to your `/etc/hosts` file:
   ```
    sudo echo "$(minikube ip) openproject.local nextcloud.local keycloak.local" | sudo tee -a /etc/hosts
   ```

Access the services via the following URLs:

- OpenProject: [https://openproject.local](https://openproject.local)
- Nextcloud: [https://nextcloud.local](https://nextcloud.local)
- Keycloak: [https://keycloak.local](https://keycloak.local)

## Configuring the Setup

See the [environments/default/config.yaml](https://github.com/saw-jan/opnc-helm-chart/blob/master/environments/default/config.yaml) file for configuration options.

## Serve From Git Branch

You can serve the OpenProject server using a specific git branch. Set the following config in the [config.yaml](./environments/default/config.yaml) file:

```yaml
openproject:
  gitSourceBranch: '<git-branch-name>'
```

_**NOTE**: This can take a long time to build the source code and deploy the application._

## Trust Self-Signed Certificates

If you are using self-signed certificates, you may need to trust them in your browser. Follow these steps:

1. Get the certificate from the cluster:

   ```bash
   kubectl get secret opnc-ca-secret -o jsonpath='{.data.ca\.crt}' | base64 -d > opnc-root-ca.crt
   ```

2. Import the certificate:

   **a. Linux**

   ```bash
   sudo cp opnc-root-ca.crt /usr/local/share/ca-certificates/
   sudo update-ca-certificates
   ```

   Import the certificate into the certificates store (for browsers):

   ```bash
   certutil -A -n "NC-OP Integration Root CA" -t TC -d sql:"$HOME/.pki/nssdb" -i opnc-root-ca.crt
   ```

   **b. macOS**

   ```bash
   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain opnc-root-ca.crt
   ```
