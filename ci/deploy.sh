#!/bin/bash
set -eu

# Decrypt a private SSH key having its public key registered on GitHub. It will
# be used to establish an identity with rights to push to the repo hosting our
# Helm charts: https://github.com/dask/helm-chart
openssl aes-256-cbc -K $encrypted_fc243309ab48_key -iv $encrypted_fc243309ab48_iv -in ci/id_rsa.enc -out ci/id_rsa -d
chmod 0400 ci/id_rsa

# Activate logging of bash commands now that the sensitive stuff is done
set -x

# As chartpress uses git to push to our Helm chart repository, we configure
# git ahead of time to use the identity we decrypted earlier.
export GIT_SSH_COMMAND="ssh -i ${PWD}/ci/id_rsa"

chartpress --commit-range "${TRAVIS_COMMIT_RANGE}" --tag "${TRAVIS_TAG}" --publish-chart