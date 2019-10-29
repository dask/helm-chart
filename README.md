# Dask Helm Chart Static Site

This branch contains the static website that makes up the Dask [Helm Chart repository](https://helm.sh/docs/chart_repository/).

⚠️ Some of the content in this branch is generated automatically by [chartpress](https://github.com/jupyterhub/chartpress) and should not be modified manually. This includes the `index.yaml` manifest and `*.tgz` chart payloads.

```
gh-pages/
  |
  |- index.yaml  # Chart manifest
  |
  |- dask-0.1.0.tgz  # Chart payloads in the format {name}-{version}.tgz
```

The rest of the content in the branch are additional resources to enable [GitHub Pages](https://pages.github.com/) to build and serve a human readable website to accompany the machine readable content. The website is dynamically generated using [Jekyll](https://jekyllrb.com/) and will show information about the charts listed in `index.yaml`.

```
gh-pages/
  |
  |- _config.yaml  # Configuration for Jekyll
  |
  |- index.md  # Index page for the website with content rendered from `index.yaml` and `_config.yaml`
  |
  |- Gemfile[.lock]  # Ruby gem versions for Jekyll and dependencies
  |
  |- _data/
    |
    |- index.yaml  # Symbolic link to top level index.yaml as Jekyll looks for data here
```
