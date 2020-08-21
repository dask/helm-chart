# DaskHub

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

If you wish to access the Dask Dashboard (and why wouldn't you?), you'll also
need to specify the hostname users will access your JupyterHub at. If you don't
have that, then specify the IP address. This will let users access the dashboard
from their browser.
 
```yaml
# file: config.yaml
jupyterhub:
  proxy:
    hosts:
      - "<jupyterhub url>"
    service:
      loadBalancerIP: "<ip>"
```
 
If you don't have an IP for your JupyterHub yet (if, say, you're letting
kubernetes assign it for you), then you may need to leave this blank and
do a secondary `helm install`.
 
## Install DaskHub

This example installs into the namespace `dhub`. Make sure you're
in the same directory as the `secrets.yaml` file.

```console
$ helm upgrade --wait --install --render-subchart-notes \
    dhub dask/daskhub \
    --namespace=dhub \
    --version=0.0.1 \
    --values=secrets.yaml
```

The output explains how to find the IPs for your JupyterHub and Dask Gateway.

```console
$ kubectl -n dhub get service
NAME                                    TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
api-us-central1b-dhub-dask-gateway      ClusterIP      10.43.253.126   <none>          8000/TCP                     25m
dask-e10f1f0179784a60b0e4c5ba09c1ed44   ClusterIP      None            <none>          8786/TCP,8787/TCP,8788/TCP   100s
hub                                     ClusterIP      10.43.250.8     <none>          8081/TCP                     25m
proxy-api                               ClusterIP      10.43.248.47    <none>          8001/TCP                     25m
proxy-public                            LoadBalancer   10.43.244.163   35.224.253.72   443:31356/TCP,80:32352/TCP   25m
traefik-us-central1b-dhub-dask-gateway  LoadBalancer   10.43.244.244   35.223.8.79     80:31076/TCP                 25m
```

JupyterHub is available at the `proxy-public` external ip (35.224.253.72 in this example).
Dask Gateawy is available at `traefik-us-central1b-dhub-dask-gateway` (35.223.8.79).

## Creating a Dask Cluster

To create a Dask cluster, connect to the Dask Gateway

```python
>>> from dask_gateway import Gateway
>>> gateway = dask_gateway.Gateway(
...     address="http://35.223.8.79",  # traefik-us-central1b-dhub-dask-gateway
...     )
>>> gateway.list_clusters()
[]
```

Once connected to the gateway, create a cluster and connect a client.

```python
>>> cluster = gateway.new_cluster()
>>> client = cluster.get_client()
```

## Configuring JupyterHub

You might want to configure the JupyterHub user environment to remove the need
for users to specify the address and authentication type for Dask Gateawy.
This can be done by setting the following and deploying with helm.

```yaml
# values.yaml
jupyterhub:
  singleuser:
    extraEnv:
      DASK_GATEWAY__ADDRESS: "http://traefik-dhub-dask-gateway"
```

Make sure to change the value to match the release name (we used `dhub`).

With this, users should be able to connect to the Gateway by simply calling
`gateway = Gateway()`, and create clusters with `cluster = dask_gateway.GatewayCluster()`.

## Matching the user environment

Dask Clients will be running the JupyterHub's singleuser environment. To ensure
that the same environment is used for the scheduler and workers, you can provide
it as a Gateway option.

```yaml
# values.yaml
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
