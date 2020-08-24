Dask Helm Charts
================

This repository contains Dask's two helm charts.

- [dask](./dask/README.md): Install Dask on Kubernetes for a single user with Jupyter and dask-kubernetes.
- [daskhub](./daskhub/README.md): Install Dask on Kubernetes for multiple users with JupyterHub and Dask Gateway.

## Quickstart -- singleuser

Users deploying Dask for a single user should use the `dask/dask` helm chart.

```
helm repo add dask https://helm.dask.org/
helm repo update
helm install --name my-release dask/dask
```

See [dask](./dask/README.md) for more.

## Quickstart -- multiuser

Users deploying Dask for multiple users should use the `dask/daskhub` helm chart.

```
helm repo add dask https://helm.dask.org/
helm repo update
helm install --name my-release dask/daskhub
```

See [daskhub](./daskhub/README.md) for more.
