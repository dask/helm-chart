To update the helm repository perform the following:

1.  Lint your helm repository to verify that everything is ok

        helm lint dask/

2.  Create a package from your directory

        helm package dask/

    This will create a gzipped tarball to include in the gh-pages branch.
    Do not commit this file to the master branch.

3.  Checkout the gh-pages branch and add this file

        git checkout gh-pages
        git add dask*.tgz

4.  Update the index.yaml file of the repository

        helm repo index .

5.  Commit changes and push

        git commit -a -m "Add new version of dask chart"
        git push dask gh-pages
