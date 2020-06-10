#!/bin/bash

set -eu

VERSION=$1
CHART_PATH=dask/Chart.yaml

# Replace version in Chart.yaml
sed -i.bak "s/^version:.*/version: $VERSION/" $CHART_PATH
rm $CHART_PATH.bak

# Commit Chart.yaml
git commit -a -m "Bump version to $VERSION"

# Git tag new version
git tag -a $VERSION -m "Version $VERSION"

# Push upstream
git push upstream master --tags