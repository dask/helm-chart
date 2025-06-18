# How to make a release

These are the instructions on how to make a release of the Helm charts `dask`
and `daskhub` maintained in this repository.

## Background

The packaged charts are published using a GitHub Pages based website also
maintained in this repository under the `gh-pages` branch. It is available at
https://helm.dask.org in a human readable way, where `helm` inspects
https://helm.dask.org/index.yaml. For details about this, see the [`gh-pages`
branch's readme](https://github.com/dask/helm-chart/tree/gh-pages#readme).

We currently do releases of both the `dask` and `daskhub` at the same time, and
aren't maintaining a changelog for either.

The Helm charts `dask-gateway` and `dask-kubernetes-operator` also published via
this repository's GitHub Pages website are maintained at
https://github.com/dask/dask-gateway/ and
https://github.com/dask/dask-kubernetes/ respectively with independent release
processes.

## Pre-requisites

- Push rights to this GitHub repository

## Steps to make a release

1. Checkout main and make sure it is up to date.

   ```shell
   git checkout main
   git fetch origin main
   git reset --hard origin/main # warning: a destructive action
   ```

2. Decide on a version.

   We are using version tags like `2025.6.0` of the format `year.month.x` where
   the month number _must not_ include a leading zero and the last number should
   either be zero or incremented if more than one release is made in a month.

3. Use `tbump` to push a git tag.

   ```shell
   pip install tbump

   # tbump will first clarify what it will do and await your confirmation
   tbump 2025.6.0
   ```

   Following this, the [CI system] will build and publish a release, where the
   tool `chartpress` will update the Chart.yaml file's version based on the git
   tag.

[ci system]: https://github.com/dask/helm-chart/actions/workflows/publish-charts.yml
