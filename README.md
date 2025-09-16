# Openproject-Nextcloud Integration Helm Chart

- [Dependencies](#dependencies)
- [Deploy Setup Locally (Minikube)](#deploy-setup-locally-minikube)
- [Configuring the Setup](#configuring-the-setup)
- [Serve From Git Branch](#server-from-git-branch)
- [Trust Self-Signed Certificates](#trust-self-signed-certificates)

## Dependencies

- [minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download)
- [docker](https://docs.docker.com/engine/install/)
- [helm](https://helm.sh/docs/intro/install/#through-package-managers)
- [helm-diff](https://github.com/databus23/helm-diff?tab=readme-ov-file#using-helm-plugin-manager--23x) plugin
- [helmfile](https://helmfile.readthedocs.io/en/latest/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [make](https://sp21.datastructur.es/materials/guides/make-install.html)

## Deploy Setup Locally (Minikube)

1. Setup Kubernetes cluster and necessary resources:

   ```bash
   make setup
   ```

   If you need to specify cluster resources:

   ```bash
   make setup cpu=4 memory=8g
   ```

2. Deploy the integration chart:

   ```bash
   make deploy
   ```

3. Check the pods:

   ```bash
   kubectl get pods -n opnc-integration
   ```

4. Add these hosts to your `/etc/hosts` file:
   ```bash
    sudo echo "$(minikube ip) openproject.test nextcloud.test keycloak.test" | sudo tee -a /etc/hosts
   ```

NOTE: make sure at least one `setup-job-*` pod is completed successfully before proceeding.

```bash
NAME                                          READY   STATUS      RESTARTS   AGE
setup-job-5nwlm                               0/1     Error       0          17m
setup-job-mkgrf                               0/1     Completed   0          12m
```

Access the services via the following URLs:

- OpenProject: [https://openproject.test](https://openproject.test)
- Nextcloud: [https://nextcloud.test](https://nextcloud.test)
- Keycloak: [https://keycloak.test](https://keycloak.test)

To uninstall the deployment, run:

```bash
make teardown
```

or if you want to delete the K8s cluster as well, run:

```bash
make teardown-all
```

## Configuring the Setup

⚠️ Do not edit `charts/opnc-integration/values.yaml` directly.
All configuration must go into [environments/default/config.yaml](https://github.com/saw-jan/opnc-helm-chart/blob/master/environments/default/config.yaml).
This file overrides the chart defaults and is the source of truth for deployments.

### Example: Changing app version

To change the version of the `integration_openproject` app in Nextcloud:

```yaml
# environments/default/config.yaml
nextcloud:
  extraApps:
    - name: integration_openproject
      version: '2.8.1'
```

## Serve From Git Branch

You can serve the OpenProject and Nextcloud servers using a specific git branch. Set the following config in the [config.yaml](./environments/default/config.yaml) file:

```yaml
openproject:
  gitSourceBranch: '<git-branch-name>'

nextcloud:
  gitSourceBranch: '<git-branch-name>'
```

Similarly, you can enable Nextcloud apps using a specific git branch:

```yaml
nextcloud:
  enableApps:
    - name: 'app_name'
      gitBranch: '<app-git-branch>'
```

_**NOTE**: This can take a long time to build the source code and deploy the application._

## Serve OpenProject From Local Branch

You can serve the OpenProject using the local source path. Run the following command:

```bash
make deploy-dev LOCAL_SOURCE_PATH=<path-to-local-openproject-repo>
```

_**NOTE**: This can take a long time to build the source code and deploy the application._

## Trust Self-Signed Certificates

If you are using self-signed certificates, you may need to trust them in your browser. Follow these steps:

1. Get the certificate from the cluster:

   ```bash
   kubectl get secret opnc-ca-secret -n opnc-integration -o jsonpath='{.data.ca\.crt}' | base64 -d > opnc-root-ca.crt
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
