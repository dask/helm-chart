Dask is a community maintained project. We welcome contributions in the form of bug reports, documentation, code, design proposals, and more.

For general information on how to contribute see https://docs.dask.org/en/latest/develop.html.


## Project specific notes

### Pre-commit

#### Helm Lint

This project uses the `helm lint` command from [Helm](https://helm.sh/docs/using_helm/) to ensure the helm chart is valid and can be installed.

You can lint your changes yourself by running `helm lint dask` from the root of this repository.

#### Frigate

[Frigate](https://github.com/rapidsai/frigate) is a tool for automatically generating documentation for Helm charts. We use it to generate the `README.md`
files in the Chart repos from a `.frigate` jinja template file. The jinja template make use of `values.yaml` and `Chart.yaml` content, so we monitor for changes to
those as well as the generated output.
