# Changelog

This document logs changes between versions of the `daskhub` helm chart.

## 2021.6.1

### Version Updates

* Updated JupyterHub helm chart to version 1.0.1. See the [zero-to-jupyterhub-k8s changelog](https://github.com/jupyterhub/zero-to-jupyterhub-k8s/blob/main/CHANGELOG.md#10) for instructions on upgrading.
* Updated default `singleuser` image to use [`pangeo/base-notebook:2021.06.05](https://hub.docker.com/layers/pangeo/base-notebook/2021.06.05/images/sha256-c02c631921ab98ea00a206ed994359f8e0a4785a317d8c1e13e20df3362fcc2f?context=explore) with [these package versions](https://github.com/pangeo-data/pangeo-docker-images/blob/2021.06.05/base-notebook/packages.txt).
