# Openproject-Nextcloud Integration Helm Chart

## Prerequisites

- Kubernetes cluster ([minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download))
- [Docker](https://docs.docker.com/engine/install/)
- [Helm](https://helm.sh/docs/intro/install/#through-package-managers)
- [Helmfile](https://helmfile.readthedocs.io/en/latest/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

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
