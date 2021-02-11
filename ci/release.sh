#!/bin/bash

set -eu

VERSION=$1

# Commit Chart.yaml
git commit --allow-empty -m "Version $VERSION"

# Git tag new version
git tag -a $VERSION -m "Version $VERSION"

# Push upstream
git push upstream main --tags
