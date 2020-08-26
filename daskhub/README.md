
Daskhub
===========

[![Travis Build Status](https://travis-ci.com/dask/helm-chart.svg?branch=master)](https://travis-ci.com/dask/helm-chart)
[![Chart version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=chart&query=$.entries.daskhub[:1].version&color=277A9F)](https://helm.dask.org/)
[![Dask version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=Dask&query=$.entries.daskhub[:1].appVersion&color=D67548)](https://helm.dask.org/)

This chart provides a multi-user, Dask-Gateway enabled JupyterHub.
It combines the [JupyterHub](https://jupyterhub.readthedocs.io/en/stable/)
and [Dask Gateway](https://gateway.dask.org/) helm charts.

For single users, a simpler setup is supported by the `dask` helm chart.

## Chart Details

This chart will deploy the following

- A standard Dask Gateway deployment using the Dask Gateway helm chart,
  configured to use JupyterHub for authentication.
- A standard JupyterHub deployment using the JupyterHub helm chart,
  configured proxy Dask Gateway requests and set Dask Gateway-related
  environment variables.

## Prepare Configuration File

In this step, we'll prepare a YAML configuration file with the fields
required by the DaskHub helm chart. It will contain some secret
keys, which should not be checked into version control in plaintext.

We need two random hex strings that will be used as keys, one for
JupyterHub and one for Dask Gateway.

Run the following command, and copy the output. This is our `token-1`.

```console
openssl rand -hex 32  # generate token-1
```

Run command again and copy the output. This is our `token-2`.

```console
openssl rand -hex 32  # generate token-2
```

Now substitute those two values for `<token-1>` and `<token-2>` below.
Note that `<token-2>` is used twice, once for `jupyterhub.hub.services.dask-gateway.apiToken`, and a second time for `dask-gateway.gateway.auth.jupyterhub.apiToken`.


```yaml
# file: secrets.yaml
jupyterhub:
  proxy:
    secretToken: "<token-1>"
  hub:
    services:
      dask-gateway:
        apiToken: "<token-2>"

dask-gateway:
  gateway:
    auth:
      jupyterhub:
        apiToken: "<token-2>"
```

## Install DaskHub

This example installs into the namespace `dhub`. Make sure you're
in the same directory as the `secrets.yaml` file.

```console
$ helm upgrade --wait --install --render-subchart-notes \
    dhub dask/daskhub \
    --namespace=dhub \
    --version=0.0.1 \
    --values=secrets.yaml \
    --values=config.yaml
```

The output explains how to find the IPs for your JupyterHub and Dask Gateway.

```console
$ kubectl -n dhub get service proxy-public
NAME           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
proxy-public   LoadBalancer   10.43.249.239   35.202.158.223   443:31587/TCP,80:30500/TCP   2m40s
```

JupyterHub is available at the `proxy-public` external ip (35.202.158.223 in this example).

## Creating a Dask Cluster

To create a Dask cluster users can create a `dask_gateway.GatewayCluster`.

```python
>>> from dask_gateway import GatewayCluster
>>> cluster = gateway.new_cluster()
>>> client = cluster.get_client()
```

If necessary (say to set options, create clusters that outlive the notebook session, etc.),
users can connect to the Gateway


```python
>>> from dask_gateway import Gateway
>>> gateway = Gateway()
```

See https://gateway.dask.org/ for more on using Dask Gateway.

## Matching the user environment

Dask Clients will be running the JupyterHub's singleuser environment. To ensure
that the same environment is used for the scheduler and workers, you can provide
it as a Gateway option.

```yaml
# config.yaml
jupyterhub:
 singleuser:
   extraEnv:
     DASK_GATEWAY__CLUSTER__OPTIONS__IMAGE: '{JUPYTER_IMAGE_SPEC}'

dask-gateway:
  extraConfig:
    optionHandler: |
      from dask_gateway_server.options import Options, Integer, Float, String
      def option_handler(options):
          if ":" not in options.image:
              raise ValueError("When specifying an image you must also provide a tag")
          return {
              "image": options.image,
          }
      c.Backend.cluster_options = Options(
          String("image", default="pangeo/base-notebook:2020.07.28", label="Image"),
          handler=option_handler,
      )
```

The user environment will need to include `dask-gateway`.

## Using dask-kubernetes instead of Dask Gateway

Users who don't need Dask Gateway can use dask-kubernetes to manage creating Dask Clusters. To use dask-kubernetes, you should set

```
# config.yaml
daskhub:
  jupyterhub:
    singleuser:
      servieAccountName: daskkubernetes

  dask-gateway:
    enabled: false
  
  dask-kubernetes:
    enabled: true
```

When deploying, helm will create a Kubernetes ServiceAccount, Role, and RoleBinding. This ensures that the pods serving JupyterHub singleusers have the eleveated permissions for starting and stopping pods.
## Configuration

The following table lists the configurable parameters of the Daskhub chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `rbac.enabled` | Create and use roles and service accounts on an rbac-enabled cluster. | `true` |
| `jupyterhub.hub.extraConfig.00-add-dask-gateway-values` |  | `"# 1. Sets `DASK_GATEWAY__PROXY_ADDRESS` in the singleuser environment.\n# 2. Adds the URL for the Dask Gateway JupyterHub service.\nimport os\n\n# These are set by jupyterhub.\nrelease_name = os.environ[\"HELM_RELEASE_NAME\"]\nrelease_namespace = os.environ[\"POD_NAMESPACE\"]\n\nc.KubeSpawner.environment[\"DASK_GATEWAY__ADDRESS\"] = \"http://proxy-public/services/dask-gateway\"\nc.KubeSpawner.environment[\"DASK_GATEWAY__PROXY_ADDRESS\"] = \"gateway://traefik-{}-dask-gateway.{}:80\".format(release_name, release_namespace)\n\n# Adds Dask Gateway as a JupyterHub service to make the gateway available at\n# {HUB_URL}/services/dask-gateway\nservice_url = \"http://traefik-{}-dask-gateway.{}\".format(release_name, release_namespace)\nfor service in c.JupyterHub.services:\n    if service[\"name\"] == \"dask-gateway\":\n        if not service.get(\"url\", None):\n            print(\"Adding dask-gateway service URL\")\n            service[\"url\"] = service_url\n        break\nelse:\n    print(\"dask-gateway service not found. Did you set jupyterhub.hub.services.dask-gateway.apiToken?\")\n"` |
| `jupyterhub.singleuser.image.name` | Image to use for singleuser environment. must include dask-gateyway. | `"pangeo/base-notebook"` |
| `jupyterhub.singleuser.image.tag` |  | `"2020.07.28"` |
| `jupyterhub.singleuser.defaultUrl` | Use jupyterlab by defualt. | `"/lab"` |
| `jupyterhub.singleuser.extraEnv.DASK_GATEWAY__ADDRESS` | Internal address to connect to the dask gateway. | `"http://proxy-public/services/dask-gateway"` |
| `jupyterhub.singleuser.extraEnv.DASK_GATEWAY__PUBLIC_ADDRESS` | Sets the dask dashboard link in cluster and client reprs. | `"/services/dask-gateway/"` |
| `jupyterhub.singleuser.extraEnv.DASK_GATEWAY__AUTH__TYPE` | Use jupyterhub to authenticate with dask gateway. | `"jupyterhub"` |
| `dask-gateway.enabled` | Enabling dask-gateway will install dask gateway as a dependency. | `true` |
| `dask-gateway.gateway.prefix` | Users connect to the gateway through the jupyterhub service. | `"/services/dask-gateway"` |
| `dask-gateway.gateway.auth.type` | Use jupyterhub to authenticate with dask gateway | `"jupyterhub"` |
| `dask-gateway.traefik.service.type` | Access dask gateway through jupyterhub. to access the gateway from outside jupyterhub, this must be changed to a `loadbalancer`. | `"ClusterIP"` |
| `dask-kubernetes.enabled` |  | `false` |





