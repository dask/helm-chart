# Dask Helm Chart

[![Travis Build Status](https://travis-ci.com/dask/helm-chart.svg?branch=master)](https://travis-ci.com/dask/helm-chart)
[![Chart version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=chart&query=$.entries.dask[:1].version&color=277A9F)](https://helm.dask.org/)
[![Dask version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=Dask&query=$.entries.dask[:1].appVersion&color=D67548)](https://helm.dask.org/)


Dask allows distributed computation in Python.

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

## Default Configuration

The following tables list the configurable parameters of the Dask chart and
their default values.

### Dask scheduler

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `scheduler.name`         | Dask scheduler name     | `scheduler`    |
| `scheduler.image`        | Container image name    | `daskdev/dask` |
| `scheduler.imageTag`     | Container image tag     | `1.1.5`        |
| `scheduler.replicas`     | k8s deployment replicas | `1`            |
| `scheduler.tolerations`  | Tolerations             | `[]`           |
| `scheduler.nodeSelector` | nodeSelector            | `{}`           |
| `scheduler.affinity`     | Container affinity      | `{}`           |

### Dask webUI

| Parameter                   | Description                        | Default              |
| --------------------------- | ---------------------------------- | -------------------- |
| `webUI.name`                | Dask webui name                    | `webui`              |
| `webUI.servicePort`         | k8s service port                   | `80`                 |
| `webUI.ingress.enabled`     | Enable ingress controller resource | false                |
| `webUI.ingress.hostname`    | Ingress resource hostnames         | dask-ui.example.com  |
| `webUI.ingress.tls`         | Ingress TLS configuration          | false                |
| `webUI.ingress.secretName`  | Ingress TLS secret name            | `dask-scheduler-tls` |
| `webUI.ingress.annotations` | Ingress annotations configuration  | null                 |

### Dask worker

| Parameter             | Description                      | Default        |
| --------------------- | -------------------------------- | -------------- |
| `worker.name`         | Dask worker name                 | `worker`       |
| `worker.image`        | Container image name             | `daskdev/dask` |
| `worker.imageTag`     | Container image tag              | `1.1.5`        |
| `worker.replicas`     | k8s hpa and deployment replicas  | `3`            |
| `worker.resources`    | Container resources              | `{}`           |
| `worker.tolerations`  | Tolerations                      | `[]`           |
| `worker.nodeSelector` | nodeSelector                     | `{}`           |
| `worker.affinity`     | Container affinity               | `{}`           |
| `worker.port`         | Worker port (defaults to random) | `""`           |

### Jupyter

| Parameter                     | Description                        | Default                 |
| ----------------------------- | ---------------------------------- | ----------------------- |
| `jupyter.name`                | Jupyter name                       | `jupyter`               |
| `jupyter.enabled`             | Include optional Jupyter server    | `true`                  |
| `jupyter.image`               | Container image name               | `daskdev/dask-notebook` |
| `jupyter.imageTag`            | Container image tag                | `1.1.5`                 |
| `jupyter.replicas`            | k8s deployment replicas            | `1`                     |
| `jupyter.servicePort`         | k8s service port                   | `80`                    |
| `jupyter.resources`           | Container resources                | `{}`                    |
| `jupyter.tolerations`         | Tolerations                        | `[]`                    |
| `jupyter.nodeSelector`        | nodeSelector                       | `{}`                    |
| `jupyter.affinity`            | Container affinity                 | `{}`                    |
| `jupyter.ingress.enabled`     | Enable ingress controller resource | false                   |
| `jupyter.ingress.hostname`    | Ingress resource hostnames         | dask-ui.example.com     |
| `jupyter.ingress.tls`         | Ingress TLS configuration          | false                   |
| `jupyter.ingress.secretName`  | Ingress TLS secret name            | `dask-jupyter-tls`      |
| `jupyter.ingress.annotations` | Ingress annotations configuration  | null                    |

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

## Releasing

Releases of the Helm chart are automatically pushed to the `gh-pages` branch by Travis CI when git tags are created.

Before releasing you may want to ensure the chart is up to date with the latest Docker images and Dask versions:

- Update the image tags in `dask/values.yaml` to reflect the [latest release of the Dask Docker images](https://github.com/dask/dask-docker/releases).
- Update the `appVersion` value in `dask/Chart.yaml` to also reflect this version.

Then to perform a release you need to create and push a new tag.

- Update the `version` key in `dask/Chart.yaml` with the new chart version `x.x.x`.
- Add a release commit `git commit -a -m "bump version to x.x.x"`.
- Tag the commit `git tag -a x.x.x -m 'Version x.x.x'`.
- Push the tags `git push upstream master --tags`.
- Travis CI will automatically build and release to the chart repository.
