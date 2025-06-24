[![GitHub workflow status - Dask](https://img.shields.io/github/workflow/status/dask/helm-chart/Test%20dask%20chart?logo=github&label=dask)](https://github.com/dask/helm-chart/actions)
[![Dask chart version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=dask&query=$.entries.dask[:1].version&color=277A9F&logo=helm)](https://helm.dask.org/)
[![Dask version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=dask&query=$.entries.dask[:1].appVersion&color=D67548&logo=python&logoColor=white)](https://dask.org/)

[![GitHub workflow status - DaskHub](https://img.shields.io/github/workflow/status/dask/helm-chart/Test%20daskhub%20chart?logo=github&label=daskhub)](https://github.com/dask/helm-chart/actions)
[![DaskHub chart version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=daskhub&query=$.entries.daskhub[:1].version&color=277A9F&logo=helm)](https://helm.dask.org/)
[![Dask version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=daskhub&query=$.entries.daskhub[:1].appVersion&color=D67548&logo=python&logoColor=white)](https://dask.org/)

# Helm Charts

This repository contains two Helm charts.

- [dask](./dask/README.md): Install Dask on Kubernetes for a single user with Jupyter and [dask-kubernetes](https://github.com/dask/dask-kubernetes).
- [daskhub](./daskhub/README.md): Install Dask on Kubernetes for multiple users with JupyterHub and [dask-gateway](https://github.com/dask/dask-gateway).

## Helm Chart Repository

This repository also contains a `gh-pages` branch that using GitHub Pages is
built into the website available at https://helm.dask.org. This website is human
readable but also readable by `helm` as a Helm chart repository thanks to a
`index.yaml` file.

The Helm chart repository also publishes Helm charts not maintained in this
repository, specifically `dask-gateway` and `dask-kubernetes-operator`.

## Single-user Quickstart

Users deploying Dask for a single user should use the `dask/dask` helm chart.

```
helm repo add dask https://helm.dask.org/
helm repo update
helm install my-release dask/dask
```

See [dask](./dask/README.md) for more.

## Multi-user Quickstart

Users deploying Dask for multiple users should use the `dask/daskhub` helm chart.

```
helm repo add dask https://helm.dask.org/
helm repo update
helm install --name my-release dask/daskhub
```

See [daskhub](./daskhub/README.md) for more.
