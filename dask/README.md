
Dask
===========

[![Travis Build Status](https://travis-ci.com/dask/helm-chart.svg?branch=master)](https://travis-ci.com/dask/helm-chart)
[![Chart version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=chart&query=$.entries.dask[:1].version&color=277A9F)](https://helm.dask.org/)
[![Dask version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=Dask&query=$.entries.dask[:1].appVersion&color=D67548)](https://helm.dask.org/)

- <https://dask.org>
- <https://jupyter.org/>

## Chart Details

This chart will deploy the following:

- 1 x Dask scheduler with port 8786 (scheduler) and 80 (Web UI) exposed on an external LoadBalancer (default)
- 3 x Dask workers that connect to the scheduler
- 1 x Jupyter notebook (optional) with port 80 exposed on an external LoadBalancer (default)
- All using Kubernetes Deployments

> **Tip**: See the [Kubernetes Service Type Docs](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)
> for the differences between ClusterIP, NodePort, and LoadBalancer.

## Installing the Chart

First we need to add the Dask helm repo to our local helm config.

```bash
helm repo add dask https://helm.dask.org/
helm repo update
```

To install the chart with the release name `my-release`:

```bash
helm install --name my-release dask/dask
```

Depending on how your cluster was setup, you may also need to specify
a namespace with the following flag: `--namespace my-namespace`.

### Upgrading an existing installation that used stable/dask

This chart is fully compatible with the previous chart, it is just a change of location.
If you have an existing deployment of Dask which used the now-deprecated `stable/dask` chart
you can upgrade it by changing the repo name in your upgrade command.

```bash
# Add the Dask repo if you haven't already
helm repo add dask https://helm.dask.org/
helm repo update

# Upgrade your deployment that was previous created with stable/dask
helm upgrade my-release dask/dask
```
## Configuration

The following table lists the configurable parameters of the Dask chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `scheduler.name` | Dask scheduler name. | `"scheduler"` |
| `scheduler.image.repository` | Container image repository. | `"daskdev/dask"` |
| `scheduler.image.tag` | Container image tag. | `"2.30.0"` |
| `scheduler.image.pullPolicy` | Container image pull policy. | `"IfNotPresent"` |
| `scheduler.image.pullSecrets` | Container image [pull secrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/). | `null` |
| `scheduler.replicas` | Number of schedulers (should always be 1). | `1` |
| `scheduler.serviceType` | Scheduler service type. set to `loadbalancer` to expose outside of your cluster. | `"ClusterIP"` |
| `scheduler.servicePort` | Scheduler service internal port. | `8786` |
| `scheduler.extraArgs` | Extra cli arguments to be passed to the scheduler | `[]` |
| `scheduler.resources` | Scheduler pod resources. see `values.yaml` for example values. | `{}` |
| `scheduler.tolerations` | Tolerations. | `[]` |
| `scheduler.affinity` | Container affinity. | `{}` |
| `scheduler.nodeSelector` | Node selector. | `{}` |
| `scheduler.securityContext` | Security context. | `{}` |
| `webUI.name` | Dask webui name. | `"webui"` |
| `webUI.servicePort` | Webui service internal port. | `80` |
| `webUI.ingress.enabled` | Enable ingress. | `false` |
| `webUI.ingress.tls` | Ingress should use tls. | `false` |
| `webUI.ingress.hostname` | Ingress hostname. | `"dask-ui.example.com"` |
| `webUI.ingress.annotations` | Ingress annotations. see `values.yaml` for example values. | `null` |
| `worker.name` | Dask worker name. | `"worker"` |
| `worker.image.repository` | Container image repository. | `"daskdev/dask"` |
| `worker.image.tag` | Container image tag. | `"2.30.0"` |
| `worker.image.pullPolicy` | Container image pull policy. | `"IfNotPresent"` |
| `worker.image.dask_worker` | Dask worker command. e.g `dask-cuda-worker` for gpu worker. | `"dask-worker"` |
| `worker.image.pullSecrets` | Container image [pull secrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/). | `null` |
| `worker.replicas` | Number of workers. | `3` |
| `worker.default_resources.cpu` | Default cpu (deprecated use `resources`). | `1` |
| `worker.default_resources.memory` | Default memory (deprecated use `resources`). | `"4GiB"` |
| `worker.env` | Environment variables. see `values.yaml` for example values. | `null` |
| `worker.extraArgs` | Extra cli arguments to be passed to the worker | `[]` |
| `worker.resources` | Worker pod resources. see `values.yaml` for example values. | `{}` |
| `worker.mounts` | Worker pod volumes and volume mounts, mounts.volumes follows kuberentes api v1 volumes spec. mounts.volumemounts follows kubernetesapi v1 volumemount spec | `{}` |
| `worker.tolerations` | Tolerations. | `[]` |
| `worker.affinity` | Container affinity. | `{}` |
| `worker.nodeSelector` | Node selector. | `{}` |
| `worker.securityContext` | Security context. | `{}` |
| `jupyter.name` | Jupyter name. | `"jupyter"` |
| `jupyter.enabled` | Enable/disable the bundled jupyter notebook. | `true` |
| `jupyter.rbac` | Create rbac service account and role to allow jupyter pod to scale worker pods and access logs. | `true` |
| `jupyter.image.repository` | Container image repository. | `"daskdev/dask-notebook"` |
| `jupyter.image.tag` | Container image tag. | `"2.30.0"` |
| `jupyter.image.pullPolicy` | Container image pull policy. | `"IfNotPresent"` |
| `jupyter.image.pullSecrets` | Container image [pull secrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/). | `null` |
| `jupyter.replicas` | Number of notebook servers. | `1` |
| `jupyter.serviceType` | Scheduler service type. set to `loadbalancer` to expose outside of your cluster. | `"ClusterIP"` |
| `jupyter.servicePort` | Jupyter service internal port. | `80` |
| `jupyter.password` | Password hash. default hash corresponds to the password `dask`. | `"sha1:aae8550c0a44:9507d45e087d5ee481a5ce9f4f16f37a0867318c"` |
| `jupyter.env` | Environment variables. see `values.yaml` for example values. | `null` |
| `jupyter.command` | Container command. | `null` |
| `jupyter.args` | Container arguments. | `null` |
| `jupyter.extraConfig` |  | `"# Extra Jupyter config goes here\n# E.g\n# c.NotebookApp.port = 8888"` |
| `jupyter.resources` | Jupyter pod resources. see `values.yaml` for example values. | `{}` |
| `jupyter.mounts` | Worker pod volumes and volume mounts, mounts.volumes follows kuberentes api v1 volumes spec. mounts.volumemounts follows kubernetesapi v1 volumemount spec | `{}` |
| `jupyter.tolerations` | Tolerations. | `[]` |
| `jupyter.affinity` | Container affinity. | `{}` |
| `jupyter.nodeSelector` | Node selector. | `{}` |
| `jupyter.securityContext` | Security context. | `{}` |
| `jupyter.serviceAccountName` | Service account for use with rbac | `"dask-jupyter"` |
| `jupyter.ingress.enabled` | Enable ingress. | `false` |
| `jupyter.ingress.tls` | Ingress should use tls. | `false` |
| `jupyter.ingress.hostname` | Ingress hostname. | `"dask-jupyter.example.com"` |
| `jupyter.ingress.annotations` | Ingress annotations. see `values.yaml` for example values. | `null` |

#### Jupyter Password

When launching the Jupyter server, you will be prompted for a password. The
default password set in [values.yaml](/dask/values.yaml) is `dask`.

```yaml
jupyter:
  ...
  password: 'sha1:aae8550c0a44:9507d45e087d5ee481a5ce9f4f16f37a0867318c' # 'dask'
```

To change this password, run `jupyter notebook password` in the command-line,
example below:

```bash
$ jupyter notebook password
Enter password: dask
Verify password: dask
[NotebookPasswordApp] Wrote hashed password to /home/dask/.jupyter/jupyter_notebook_config.json

$ cat /home/dask/.jupyter/jupyter_notebook_config.json
{
  "NotebookApp": {
    "password": "sha1:aae8550c0a44:9507d45e087d5ee481a5ce9f4f16f37a0867318c"
  }
}
```

Replace the `jupyter.password` field in [values.yaml](/dask/values.yaml) with the
hash generated for your new password.

## Custom Configuration

If you want to change the default parameters, you can do this in two ways.

### YAML Config Files

You can change the default parameters in `values.yaml`, or create your own
custom YAML config file, and specify this file when installing your chart with
the `-f` flag. Example:

```bash
helm install --name my-release -f values.yaml dask/dask
```

> **Tip**: You can use the default [values.yaml](/dask/values.yaml) for reference

### Command-Line Arguments

If you want to change parameters for a specific install without changing
`values.yaml`, you can use the `--set key=value[,key=value]` flag when running
`helm install`, and it will override any default values. Example:

```bash
helm install --name my-release --set jupyter.enabled=false dask/dask
```

### Customizing Python Environment

The default `daskdev/dask` images have a standard Miniconda installation along
with some common packages like NumPy and Pandas. You can install custom packages
with either Conda or Pip using optional environment variables. This happens
when your container starts up.

> **Note**: The `IP:PORT` of this chart's services will not be accessible until
> extra packages finish installing. Expect to wait at least a minute for the
> Jupyter Server to be accessible if adding packages below, like `numba`. This
> time will vary depending on which extra packages you choose to install.

Consider the following YAML config as an example:

```yaml
jupyter:
  env:
  - name: EXTRA_CONDA_PACKAGES
    value: numba xarray -c conda-forge
  - name: EXTRA_PIP_PACKAGES
    value: s3fs dask-ml --upgrade

worker:
  env:
  - name: EXTRA_CONDA_PACKAGES
    value: numba xarray -c conda-forge
  - name: EXTRA_PIP_PACKAGES
    value: s3fs dask-ml --upgrade
```

> **Note**: The Jupyter and Dask-worker environments should have matching
> software environments, at least where a user is likely to distribute that
> functionality.

### RBAC

By default the Jupyter pod will be given an RBAC role via a service account which allows you to scale
deployments and access pod logs from the Jupyter pod.

For example to scale the workers you can run the following command from the Jupyter terminal.

```bash
kubectl scale deployment dask-worker --replicas=10
```

You can also get pod logs using kubectl.

```bash
# List pods
kubectl get pods

# Watch pod logs
kubectl logs -f {podname}
```

The RBAC role will give the Jupyter pod access to view all pods and update all deployments in the namespace you
install the Helm Chart in. If you wish to disable this you must disable the Jupyter RBAC and unset the service account.

```yaml
jupyter:
  rbac: false
  serviceAccountName: null
```

Also see the [dask-kubernetes documentation](https://kubernetes.dask.org/en/latest/api.html#dask_kubernetes.HelmCluster)
for the `HelmCluster` cluster manager for managing workers from within your Python session.

## Maintaining

### Generating the README

This repo uses [Frigate](https://frigate.readthedocs.io/en/master/index.html) to autogenerate the README. This makes it quick to keep the table
of config options up to date.

If you wish to make a change to the README body you must edit `dask/.frigate` instead.

To generate the readme run Frigate.

```
frigate gen dask > README.md
```

### Releasing

Releases of the Helm chart are automatically pushed to the `gh-pages` branch by Travis CI when git tags are created.

Before releasing you may want to ensure the chart is up to date with the latest Docker images and Dask versions:

- Update the image tags in `dask/values.yaml` to reflect the [latest release of the Dask Docker images](https://github.com/dask/dask-docker/releases).
- Update the `appVersion` value in `dask/Chart.yaml` to also reflect this version.

Then to perform a release you need to create and push a new tag.

You can either use the `ci/release.sh` script.

```
ci/release.sh x.x.x
```

Or manually run the steps below.

- Update the `version` key in `dask/Chart.yaml` with the new chart version `x.x.x`.
- For ease of releasing set the version as an environment variable `export DASK_HELM_VERSION=x.x.x`.
- Add a release commit `git commit -a -m "bump version to $DASK_HELM_VERSION"`.
- Tag the commit `git tag -a $DASK_HELM_VERSION -m "Version $DASK_HELM_VERSION"`.
- Push the tags `git push upstream master --tags`.
- Travis CI will automatically build and release to the chart repository.


