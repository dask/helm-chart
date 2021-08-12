Dask is a community maintained project. We welcome contributions in the form of bug reports, documentation, code, design proposals, and more.

For general information on how to contribute see https://docs.dask.org/en/latest/develop.html.

## Project specific notes

### Pre-commit

To ensure consistency between contributions we provide a [pre-commit](https://pre-commit.com/) config which automatically runs and fixes all linting steps when you make a commit.

To get make use of this you need to install and initialize pre-commit in your local repo.

```console
$ pip install pre-commit
$ pre-commit install
```

Then when you commit changes checks will be run automatically.

```console
$ git commit -m "My foo commit"
frigate..................................................................Passed
helmlint.................................................................Passed
[foo be22e15] My foo commit
 8 files changed, 75 insertions(+), 78 deletions(-)
 ...
```

The linting steps may reject your commit or make formatting changes to files which need to be staged and commited.

Linting steps:

#### Helm Lint

This project uses the `helm lint` command from [Helm](https://helm.sh/docs/using_helm/) to ensure the helm chart is valid and can be installed.

You can lint your changes yourself by running `pre-commit run --all-files` from the root of this repository.

#### Frigate

[Frigate](https://github.com/rapidsai/frigate) is a tool for automatically generating documentation for Helm charts. We use it to generate the `README.md`
files in the Chart repos from a `.frigate` jinja template file. The jinja template make use of `values.yaml` and `Chart.yaml` content, so we monitor for changes to
those as well as the generated output.

You can generate these files yourself with `pre-commit run --all-files`.
