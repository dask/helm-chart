
Daskhub
===========

[![GitHub workflow status - DaskHub](https://img.shields.io/github/workflow/status/dask/helm-chart/Test%20daskhub%20chart?logo=github&label=daskhub)](https://github.com/dask/helm-chart/actions)
[![DaskHub chart version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=daskhub&query=$.entries.daskhub[:1].version&color=277A9F&logo=helm)](https://helm.dask.org/)
[![Dask version](https://img.shields.io/badge/dynamic/yaml?url=https://helm.dask.org/index.yaml&label=daskhub&query=$.entries.daskhub[:1].appVersion&color=D67548&logo=python&logoColor=white)](https://dask.org/)

This chart provides a multi-user, Dask-Gateway enabled JupyterHub.
It combines the [JupyterHub](https://jupyterhub.readthedocs.io/en/stable/)
and [Dask Gateway](https://gateway.dask.org/) helm charts.

For single users, a simpler setup is supported by the `dask` helm chart.

See [CHANGELOG](./CHANGELOG.md) for a information about changes in the `daskhub` helm chart.

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

Run the following command, and copy the output. This is our `secret-token`.

```console
openssl rand -hex 32  # generate secret-token
```

Now substitute that value for `<secret-token>` below.

```yaml
# file: secrets.yaml
jupyterhub:
  hub:
    services:
      dask-gateway:
        apiToken: "<secret-token>"

dask-gateway:
  gateway:
    auth:
      jupyterhub:
        apiToken: "<secret-token>"
```

## Install DaskHub

This example installs into the namespace `dhub`. Make sure you're
in the same directory as the `secrets.yaml` file.

```console
$ helm upgrade --wait --install --render-subchart-notes \
    dhub dask/daskhub \
    --namespace=dhub \
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
  gateway:
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
| `rbac.enabled` | Create and use roles and service accounts on an RBAC-enabled cluster. | `true` |
| `jupyterhub.hub.extraConfig.00-add-dask-gateway-values` |  | `"# 1. Sets `DASK_GATEWAY__PROXY_ADDRESS` in the singleuser environment.\n# 2. Adds the URL for the Dask Gateway JupyterHub service.\nimport os\n\n# These are set by jupyterhub.\nrelease_name = os.environ[\"HELM_RELEASE_NAME\"]\nrelease_namespace = os.environ[\"POD_NAMESPACE\"]\n\nif \"PROXY_HTTP_SERVICE_HOST\" in os.environ:\n    # https is enabled, we want to use the internal http service.\n    gateway_address = \"http://{}:{}/services/dask-gateway/\".format(\n        os.environ[\"PROXY_HTTP_SERVICE_HOST\"],\n        os.environ[\"PROXY_HTTP_SERVICE_PORT\"],\n    )\n    print(\"Setting DASK_GATEWAY__ADDRESS {} from HTTP service\".format(gateway_address))\nelse:\n    gateway_address = \"http://proxy-public/services/dask-gateway\"\n    print(\"Setting DASK_GATEWAY__ADDRESS {}\".format(gateway_address))\n\n# Internal address to connect to the Dask Gateway.\nc.KubeSpawner.environment.setdefault(\"DASK_GATEWAY__ADDRESS\", gateway_address)\n# Internal address for the Dask Gateway proxy.\nc.KubeSpawner.environment.setdefault(\"DASK_GATEWAY__PROXY_ADDRESS\", \"gateway://traefik-{}-dask-gateway.{}:80\".format(release_name, release_namespace))\n# Relative address for the dashboard link.\nc.KubeSpawner.environment.setdefault(\"DASK_GATEWAY__PUBLIC_ADDRESS\", \"/services/dask-gateway/\")\n# Use JupyterHub to authenticate with Dask Gateway.\nc.KubeSpawner.environment.setdefault(\"DASK_GATEWAY__AUTH__TYPE\", \"jupyterhub\")\n\n# Adds Dask Gateway as a JupyterHub service to make the gateway available at\n# {HUB_URL}/services/dask-gateway\nservice_url = \"http://traefik-{}-dask-gateway.{}\".format(release_name, release_namespace)\nfor service in c.JupyterHub.services:\n    if service[\"name\"] == \"dask-gateway\":\n        if not service.get(\"url\", None):\n            print(\"Adding dask-gateway service URL\")\n            service.setdefault(\"url\", service_url)\n        break\nelse:\n    print(\"dask-gateway service not found. Did you set jupyterhub.hub.services.dask-gateway.apiToken?\")\n"` |
| `jupyterhub.singleuser.image.name` | Image to use for singleuser environment. Must include dask-gateway. | `"pangeo/base-notebook"` |
| `jupyterhub.singleuser.image.tag` |  | `"2021.06.05"` |
| `jupyterhub.singleuser.defaultUrl` | Use jupyterlab by defualt. | `"/lab"` |
| `dask-gateway.enabled` | Enabling dask-gateway will install Dask Gateway as a dependency. | `true` |
| `dask-gateway.gateway.prefix` | Users connect to the Gateway through the JupyterHub service. | `"/services/dask-gateway"` |
| `dask-gateway.gateway.auth.type` | Use JupyterHub to authenticate with Dask Gateway | `"jupyterhub"` |
| `dask-gateway.traefik.service.type` | Access Dask Gateway through JupyterHub. To access the Gateway from outside JupyterHub, this must be changed to a `LoadBalancer`. | `"ClusterIP"` |
| `dask-kubernetes.enabled` |  | `false` |
| `jupyterhub.fullnameOverride` |  | `""` |
| `jupyterhub.nameOverride` |  | `null` |
| `jupyterhub.custom` |  | `{}` |
| `jupyterhub.imagePullSecret.create` |  | `false` |
| `jupyterhub.imagePullSecret.automaticReferenceInjection` |  | `true` |
| `jupyterhub.imagePullSecret.registry` |  | `null` |
| `jupyterhub.imagePullSecret.username` |  | `null` |
| `jupyterhub.imagePullSecret.password` |  | `null` |
| `jupyterhub.imagePullSecret.email` |  | `null` |
| `jupyterhub.imagePullSecrets` |  | `[]` |
| `jupyterhub.hub.config.JupyterHub.admin_access` |  | `true` |
| `jupyterhub.hub.config.JupyterHub.authenticator_class` |  | `"dummy"` |
| `jupyterhub.hub.service.type` |  | `"ClusterIP"` |
| `jupyterhub.hub.service.annotations` |  | `{}` |
| `jupyterhub.hub.service.ports.nodePort` |  | `null` |
| `jupyterhub.hub.service.extraPorts` |  | `[]` |
| `jupyterhub.hub.service.loadBalancerIP` |  | `null` |
| `jupyterhub.hub.baseUrl` |  | `"/"` |
| `jupyterhub.hub.cookieSecret` |  | `null` |
| `jupyterhub.hub.initContainers` |  | `[]` |
| `jupyterhub.hub.fsGid` |  | `1000` |
| `jupyterhub.hub.nodeSelector` |  | `{}` |
| `jupyterhub.hub.tolerations` |  | `[]` |
| `jupyterhub.hub.concurrentSpawnLimit` |  | `64` |
| `jupyterhub.hub.consecutiveFailureLimit` |  | `5` |
| `jupyterhub.hub.activeServerLimit` |  | `null` |
| `jupyterhub.hub.deploymentStrategy.type` |  | `"Recreate"` |
| `jupyterhub.hub.db.type` |  | `"sqlite-pvc"` |
| `jupyterhub.hub.db.upgrade` |  | `null` |
| `jupyterhub.hub.db.pvc.annotations` |  | `{}` |
| `jupyterhub.hub.db.pvc.selector` |  | `{}` |
| `jupyterhub.hub.db.pvc.accessModes` |  | `["ReadWriteOnce"]` |
| `jupyterhub.hub.db.pvc.storage` |  | `"1Gi"` |
| `jupyterhub.hub.db.pvc.subPath` |  | `null` |
| `jupyterhub.hub.db.pvc.storageClassName` |  | `null` |
| `jupyterhub.hub.db.url` |  | `null` |
| `jupyterhub.hub.db.password` |  | `null` |
| `jupyterhub.hub.labels` |  | `{}` |
| `jupyterhub.hub.annotations` |  | `{}` |
| `jupyterhub.hub.command` |  | `[]` |
| `jupyterhub.hub.args` |  | `[]` |
| `jupyterhub.hub.extraConfig` |  | `{}` |
| `jupyterhub.hub.extraFiles` |  | `{}` |
| `jupyterhub.hub.extraEnv` |  | `{}` |
| `jupyterhub.hub.extraContainers` |  | `[]` |
| `jupyterhub.hub.extraVolumes` |  | `[]` |
| `jupyterhub.hub.extraVolumeMounts` |  | `[]` |
| `jupyterhub.hub.image.name` |  | `"jupyterhub/k8s-hub"` |
| `jupyterhub.hub.image.tag` |  | `"1.0.1"` |
| `jupyterhub.hub.image.pullPolicy` |  | `null` |
| `jupyterhub.hub.image.pullSecrets` |  | `[]` |
| `jupyterhub.hub.resources` |  | `{}` |
| `jupyterhub.hub.containerSecurityContext.runAsUser` |  | `1000` |
| `jupyterhub.hub.containerSecurityContext.runAsGroup` |  | `1000` |
| `jupyterhub.hub.containerSecurityContext.allowPrivilegeEscalation` |  | `false` |
| `jupyterhub.hub.lifecycle` |  | `{}` |
| `jupyterhub.hub.services` |  | `{}` |
| `jupyterhub.hub.pdb.enabled` |  | `false` |
| `jupyterhub.hub.pdb.maxUnavailable` |  | `null` |
| `jupyterhub.hub.pdb.minAvailable` |  | `1` |
| `jupyterhub.hub.networkPolicy.enabled` |  | `true` |
| `jupyterhub.hub.networkPolicy.ingress` |  | `[]` |
| `jupyterhub.hub.networkPolicy.egress` |  | `[{"to": [{"ipBlock": {"cidr": "0.0.0.0/0"}}]}]` |
| `jupyterhub.hub.networkPolicy.interNamespaceAccessLabels` |  | `"ignore"` |
| `jupyterhub.hub.networkPolicy.allowedIngressPorts` |  | `[]` |
| `jupyterhub.hub.allowNamedServers` |  | `false` |
| `jupyterhub.hub.namedServerLimitPerUser` |  | `null` |
| `jupyterhub.hub.authenticatePrometheus` |  | `null` |
| `jupyterhub.hub.redirectToServer` |  | `null` |
| `jupyterhub.hub.shutdownOnLogout` |  | `null` |
| `jupyterhub.hub.templatePaths` |  | `[]` |
| `jupyterhub.hub.templateVars` |  | `{}` |
| `jupyterhub.hub.livenessProbe.enabled` |  | `true` |
| `jupyterhub.hub.livenessProbe.initialDelaySeconds` |  | `300` |
| `jupyterhub.hub.livenessProbe.periodSeconds` |  | `10` |
| `jupyterhub.hub.livenessProbe.failureThreshold` |  | `30` |
| `jupyterhub.hub.livenessProbe.timeoutSeconds` |  | `3` |
| `jupyterhub.hub.readinessProbe.enabled` |  | `true` |
| `jupyterhub.hub.readinessProbe.initialDelaySeconds` |  | `0` |
| `jupyterhub.hub.readinessProbe.periodSeconds` |  | `2` |
| `jupyterhub.hub.readinessProbe.failureThreshold` |  | `1000` |
| `jupyterhub.hub.readinessProbe.timeoutSeconds` |  | `1` |
| `jupyterhub.hub.existingSecret` |  | `null` |
| `jupyterhub.hub.serviceAccount.annotations` |  | `{}` |
| `jupyterhub.rbac.enabled` |  | `true` |
| `jupyterhub.proxy.secretToken` |  | `null` |
| `jupyterhub.proxy.annotations` |  | `{}` |
| `jupyterhub.proxy.deploymentStrategy.type` |  | `"Recreate"` |
| `jupyterhub.proxy.deploymentStrategy.rollingUpdate` |  | `null` |
| `jupyterhub.proxy.service.type` |  | `"LoadBalancer"` |
| `jupyterhub.proxy.service.labels` |  | `{}` |
| `jupyterhub.proxy.service.annotations` |  | `{}` |
| `jupyterhub.proxy.service.nodePorts.http` |  | `null` |
| `jupyterhub.proxy.service.nodePorts.https` |  | `null` |
| `jupyterhub.proxy.service.disableHttpPort` |  | `false` |
| `jupyterhub.proxy.service.extraPorts` |  | `[]` |
| `jupyterhub.proxy.service.loadBalancerIP` |  | `null` |
| `jupyterhub.proxy.service.loadBalancerSourceRanges` |  | `[]` |
| `jupyterhub.proxy.chp.containerSecurityContext.runAsUser` | nobody user | `65534` |
| `jupyterhub.proxy.chp.containerSecurityContext.runAsGroup` | nobody group | `65534` |
| `jupyterhub.proxy.chp.containerSecurityContext.allowPrivilegeEscalation` |  | `false` |
| `jupyterhub.proxy.chp.image.name` |  | `"jupyterhub/configurable-http-proxy"` |
| `jupyterhub.proxy.chp.image.tag` |  | `"4.4.0"` |
| `jupyterhub.proxy.chp.image.pullPolicy` |  | `null` |
| `jupyterhub.proxy.chp.image.pullSecrets` |  | `[]` |
| `jupyterhub.proxy.chp.extraCommandLineFlags` |  | `[]` |
| `jupyterhub.proxy.chp.livenessProbe.enabled` |  | `true` |
| `jupyterhub.proxy.chp.livenessProbe.initialDelaySeconds` |  | `60` |
| `jupyterhub.proxy.chp.livenessProbe.periodSeconds` |  | `10` |
| `jupyterhub.proxy.chp.readinessProbe.enabled` |  | `true` |
| `jupyterhub.proxy.chp.readinessProbe.initialDelaySeconds` |  | `0` |
| `jupyterhub.proxy.chp.readinessProbe.periodSeconds` |  | `2` |
| `jupyterhub.proxy.chp.readinessProbe.failureThreshold` |  | `1000` |
| `jupyterhub.proxy.chp.resources` |  | `{}` |
| `jupyterhub.proxy.chp.defaultTarget` |  | `null` |
| `jupyterhub.proxy.chp.errorTarget` |  | `null` |
| `jupyterhub.proxy.chp.extraEnv` |  | `{}` |
| `jupyterhub.proxy.chp.nodeSelector` |  | `{}` |
| `jupyterhub.proxy.chp.tolerations` |  | `[]` |
| `jupyterhub.proxy.chp.networkPolicy.enabled` |  | `true` |
| `jupyterhub.proxy.chp.networkPolicy.ingress` |  | `[]` |
| `jupyterhub.proxy.chp.networkPolicy.egress` |  | `[{"to": [{"ipBlock": {"cidr": "0.0.0.0/0"}}]}]` |
| `jupyterhub.proxy.chp.networkPolicy.interNamespaceAccessLabels` |  | `"ignore"` |
| `jupyterhub.proxy.chp.networkPolicy.allowedIngressPorts` |  | `["http", "https"]` |
| `jupyterhub.proxy.chp.pdb.enabled` |  | `false` |
| `jupyterhub.proxy.chp.pdb.maxUnavailable` |  | `null` |
| `jupyterhub.proxy.chp.pdb.minAvailable` |  | `1` |
| `jupyterhub.proxy.traefik.containerSecurityContext.runAsUser` | nobody user | `65534` |
| `jupyterhub.proxy.traefik.containerSecurityContext.runAsGroup` | nobody group | `65534` |
| `jupyterhub.proxy.traefik.containerSecurityContext.allowPrivilegeEscalation` |  | `false` |
| `jupyterhub.proxy.traefik.image.name` |  | `"traefik"` |
| `jupyterhub.proxy.traefik.image.tag` | ref: https://hub.docker.com/_/traefik?tab=tags | `"v2.4.9"` |
| `jupyterhub.proxy.traefik.image.pullPolicy` |  | `null` |
| `jupyterhub.proxy.traefik.image.pullSecrets` |  | `[]` |
| `jupyterhub.proxy.traefik.hsts.includeSubdomains` |  | `false` |
| `jupyterhub.proxy.traefik.hsts.preload` |  | `false` |
| `jupyterhub.proxy.traefik.hsts.maxAge` | About 6 months | `15724800` |
| `jupyterhub.proxy.traefik.resources` |  | `{}` |
| `jupyterhub.proxy.traefik.labels` |  | `{}` |
| `jupyterhub.proxy.traefik.extraEnv` |  | `{}` |
| `jupyterhub.proxy.traefik.extraVolumes` |  | `[]` |
| `jupyterhub.proxy.traefik.extraVolumeMounts` |  | `[]` |
| `jupyterhub.proxy.traefik.extraStaticConfig` |  | `{}` |
| `jupyterhub.proxy.traefik.extraDynamicConfig` |  | `{}` |
| `jupyterhub.proxy.traefik.nodeSelector` |  | `{}` |
| `jupyterhub.proxy.traefik.tolerations` |  | `[]` |
| `jupyterhub.proxy.traefik.extraPorts` |  | `[]` |
| `jupyterhub.proxy.traefik.networkPolicy.enabled` |  | `true` |
| `jupyterhub.proxy.traefik.networkPolicy.ingress` |  | `[]` |
| `jupyterhub.proxy.traefik.networkPolicy.egress` |  | `[{"to": [{"ipBlock": {"cidr": "0.0.0.0/0"}}]}]` |
| `jupyterhub.proxy.traefik.networkPolicy.interNamespaceAccessLabels` |  | `"ignore"` |
| `jupyterhub.proxy.traefik.networkPolicy.allowedIngressPorts` |  | `["http", "https"]` |
| `jupyterhub.proxy.traefik.pdb.enabled` |  | `false` |
| `jupyterhub.proxy.traefik.pdb.maxUnavailable` |  | `null` |
| `jupyterhub.proxy.traefik.pdb.minAvailable` |  | `1` |
| `jupyterhub.proxy.traefik.serviceAccount.annotations` |  | `{}` |
| `jupyterhub.proxy.secretSync.containerSecurityContext.runAsUser` | nobody user | `65534` |
| `jupyterhub.proxy.secretSync.containerSecurityContext.runAsGroup` | nobody group | `65534` |
| `jupyterhub.proxy.secretSync.containerSecurityContext.allowPrivilegeEscalation` |  | `false` |
| `jupyterhub.proxy.secretSync.image.name` |  | `"jupyterhub/k8s-secret-sync"` |
| `jupyterhub.proxy.secretSync.image.tag` |  | `"1.0.1"` |
| `jupyterhub.proxy.secretSync.image.pullPolicy` |  | `null` |
| `jupyterhub.proxy.secretSync.image.pullSecrets` |  | `[]` |
| `jupyterhub.proxy.secretSync.resources` |  | `{}` |
| `jupyterhub.proxy.labels` |  | `{}` |
| `jupyterhub.proxy.https.enabled` |  | `false` |
| `jupyterhub.proxy.https.type` |  | `"letsencrypt"` |
| `jupyterhub.proxy.https.letsencrypt.contactEmail` |  | `null` |
| `jupyterhub.proxy.https.letsencrypt.acmeServer` |  | `"https://acme-v02.api.letsencrypt.org/directory"` |
| `jupyterhub.proxy.https.manual.key` |  | `null` |
| `jupyterhub.proxy.https.manual.cert` |  | `null` |
| `jupyterhub.proxy.https.secret.name` |  | `null` |
| `jupyterhub.proxy.https.secret.key` |  | `"tls.key"` |
| `jupyterhub.proxy.https.secret.crt` |  | `"tls.crt"` |
| `jupyterhub.proxy.https.hosts` |  | `[]` |
| `jupyterhub.singleuser.podNameTemplate` |  | `null` |
| `jupyterhub.singleuser.extraTolerations` |  | `[]` |
| `jupyterhub.singleuser.nodeSelector` |  | `{}` |
| `jupyterhub.singleuser.extraNodeAffinity.required` |  | `[]` |
| `jupyterhub.singleuser.extraNodeAffinity.preferred` |  | `[]` |
| `jupyterhub.singleuser.extraPodAffinity.required` |  | `[]` |
| `jupyterhub.singleuser.extraPodAffinity.preferred` |  | `[]` |
| `jupyterhub.singleuser.extraPodAntiAffinity.required` |  | `[]` |
| `jupyterhub.singleuser.extraPodAntiAffinity.preferred` |  | `[]` |
| `jupyterhub.singleuser.networkTools.image.name` |  | `"jupyterhub/k8s-network-tools"` |
| `jupyterhub.singleuser.networkTools.image.tag` |  | `"1.0.1"` |
| `jupyterhub.singleuser.networkTools.image.pullPolicy` |  | `null` |
| `jupyterhub.singleuser.networkTools.image.pullSecrets` |  | `[]` |
| `jupyterhub.singleuser.cloudMetadata.blockWithIptables` |  | `true` |
| `jupyterhub.singleuser.cloudMetadata.ip` |  | `"169.254.169.254"` |
| `jupyterhub.singleuser.networkPolicy.enabled` |  | `true` |
| `jupyterhub.singleuser.networkPolicy.ingress` |  | `[]` |
| `jupyterhub.singleuser.networkPolicy.egress` |  | `[{"to": [{"ipBlock": {"cidr": "0.0.0.0/0", "except": ["169.254.169.254/32"]}}]}]` |
| `jupyterhub.singleuser.networkPolicy.interNamespaceAccessLabels` |  | `"ignore"` |
| `jupyterhub.singleuser.networkPolicy.allowedIngressPorts` |  | `[]` |
| `jupyterhub.singleuser.events` |  | `true` |
| `jupyterhub.singleuser.extraAnnotations` |  | `{}` |
| `jupyterhub.singleuser.extraLabels.hub.jupyter.org/network-access-hub` |  | `"true"` |
| `jupyterhub.singleuser.extraFiles` |  | `{}` |
| `jupyterhub.singleuser.extraEnv` |  | `{}` |
| `jupyterhub.singleuser.lifecycleHooks` |  | `{}` |
| `jupyterhub.singleuser.initContainers` |  | `[]` |
| `jupyterhub.singleuser.extraContainers` |  | `[]` |
| `jupyterhub.singleuser.uid` |  | `1000` |
| `jupyterhub.singleuser.fsGid` |  | `100` |
| `jupyterhub.singleuser.serviceAccountName` |  | `null` |
| `jupyterhub.singleuser.storage.type` |  | `"dynamic"` |
| `jupyterhub.singleuser.storage.extraLabels` |  | `{}` |
| `jupyterhub.singleuser.storage.extraVolumes` |  | `[]` |
| `jupyterhub.singleuser.storage.extraVolumeMounts` |  | `[]` |
| `jupyterhub.singleuser.storage.static.pvcName` |  | `null` |
| `jupyterhub.singleuser.storage.static.subPath` |  | `"{username}"` |
| `jupyterhub.singleuser.storage.capacity` |  | `"10Gi"` |
| `jupyterhub.singleuser.storage.homeMountPath` |  | `"/home/jovyan"` |
| `jupyterhub.singleuser.storage.dynamic.storageClass` |  | `null` |
| `jupyterhub.singleuser.storage.dynamic.pvcNameTemplate` |  | `"claim-{username}{servername}"` |
| `jupyterhub.singleuser.storage.dynamic.volumeNameTemplate` |  | `"volume-{username}{servername}"` |
| `jupyterhub.singleuser.storage.dynamic.storageAccessModes` |  | `["ReadWriteOnce"]` |
| `jupyterhub.singleuser.image.pullPolicy` |  | `null` |
| `jupyterhub.singleuser.image.pullSecrets` |  | `[]` |
| `jupyterhub.singleuser.startTimeout` |  | `300` |
| `jupyterhub.singleuser.cpu.limit` |  | `null` |
| `jupyterhub.singleuser.cpu.guarantee` |  | `null` |
| `jupyterhub.singleuser.memory.limit` |  | `null` |
| `jupyterhub.singleuser.memory.guarantee` |  | `"1G"` |
| `jupyterhub.singleuser.extraResource.limits` |  | `{}` |
| `jupyterhub.singleuser.extraResource.guarantees` |  | `{}` |
| `jupyterhub.singleuser.cmd` |  | `"jupyterhub-singleuser"` |
| `jupyterhub.singleuser.extraPodConfig` |  | `{}` |
| `jupyterhub.singleuser.profileList` |  | `[]` |
| `jupyterhub.scheduling.userScheduler.enabled` |  | `true` |
| `jupyterhub.scheduling.userScheduler.replicas` |  | `2` |
| `jupyterhub.scheduling.userScheduler.logLevel` |  | `4` |
| `jupyterhub.scheduling.userScheduler.plugins.score.disabled` |  | `[{"name": "SelectorSpread"}, {"name": "TaintToleration"}, {"name": "PodTopologySpread"}, {"name": "NodeResourcesBalancedAllocation"}, {"name": "NodeResourcesLeastAllocated"}, {"name": "NodePreferAvoidPods"}, {"name": "NodeAffinity"}, {"name": "InterPodAffinity"}, {"name": "ImageLocality"}]` |
| `jupyterhub.scheduling.userScheduler.plugins.score.enabled` |  | `[{"name": "NodePreferAvoidPods", "weight": 161051}, {"name": "NodeAffinity", "weight": 14631}, {"name": "InterPodAffinity", "weight": 1331}, {"name": "NodeResourcesMostAllocated", "weight": 121}, {"name": "ImageLocality", "weight": 11}]` |
| `jupyterhub.scheduling.userScheduler.containerSecurityContext.runAsUser` | nobody user | `65534` |
| `jupyterhub.scheduling.userScheduler.containerSecurityContext.runAsGroup` | nobody group | `65534` |
| `jupyterhub.scheduling.userScheduler.containerSecurityContext.allowPrivilegeEscalation` |  | `false` |
| `jupyterhub.scheduling.userScheduler.image.name` |  | `"k8s.gcr.io/kube-scheduler"` |
| `jupyterhub.scheduling.userScheduler.image.tag` | ref: https://github.com/kubernetes/sig-release/blob/HEAD/releases/patch-releases.md | `"v1.19.10"` |
| `jupyterhub.scheduling.userScheduler.image.pullPolicy` |  | `null` |
| `jupyterhub.scheduling.userScheduler.image.pullSecrets` |  | `[]` |
| `jupyterhub.scheduling.userScheduler.nodeSelector` |  | `{}` |
| `jupyterhub.scheduling.userScheduler.tolerations` |  | `[]` |
| `jupyterhub.scheduling.userScheduler.pdb.enabled` |  | `true` |
| `jupyterhub.scheduling.userScheduler.pdb.maxUnavailable` |  | `1` |
| `jupyterhub.scheduling.userScheduler.pdb.minAvailable` |  | `null` |
| `jupyterhub.scheduling.userScheduler.resources` |  | `{}` |
| `jupyterhub.scheduling.userScheduler.serviceAccount.annotations` |  | `{}` |
| `jupyterhub.scheduling.podPriority.enabled` |  | `false` |
| `jupyterhub.scheduling.podPriority.globalDefault` |  | `false` |
| `jupyterhub.scheduling.podPriority.defaultPriority` |  | `0` |
| `jupyterhub.scheduling.podPriority.userPlaceholderPriority` |  | `-10` |
| `jupyterhub.scheduling.userPlaceholder.enabled` |  | `true` |
| `jupyterhub.scheduling.userPlaceholder.replicas` |  | `0` |
| `jupyterhub.scheduling.userPlaceholder.containerSecurityContext.runAsUser` | nobody user | `65534` |
| `jupyterhub.scheduling.userPlaceholder.containerSecurityContext.runAsGroup` | nobody group | `65534` |
| `jupyterhub.scheduling.userPlaceholder.containerSecurityContext.allowPrivilegeEscalation` |  | `false` |
| `jupyterhub.scheduling.userPlaceholder.resources` |  | `{}` |
| `jupyterhub.scheduling.corePods.tolerations` |  | `[{"key": "hub.jupyter.org/dedicated", "operator": "Equal", "value": "core", "effect": "NoSchedule"}, {"key": "hub.jupyter.org_dedicated", "operator": "Equal", "value": "core", "effect": "NoSchedule"}]` |
| `jupyterhub.scheduling.corePods.nodeAffinity.matchNodePurpose` |  | `"prefer"` |
| `jupyterhub.scheduling.userPods.tolerations` |  | `[{"key": "hub.jupyter.org/dedicated", "operator": "Equal", "value": "user", "effect": "NoSchedule"}, {"key": "hub.jupyter.org_dedicated", "operator": "Equal", "value": "user", "effect": "NoSchedule"}]` |
| `jupyterhub.scheduling.userPods.nodeAffinity.matchNodePurpose` |  | `"prefer"` |
| `jupyterhub.prePuller.annotations` |  | `{}` |
| `jupyterhub.prePuller.resources` |  | `{}` |
| `jupyterhub.prePuller.containerSecurityContext.runAsUser` | nobody user | `65534` |
| `jupyterhub.prePuller.containerSecurityContext.runAsGroup` | nobody group | `65534` |
| `jupyterhub.prePuller.containerSecurityContext.allowPrivilegeEscalation` |  | `false` |
| `jupyterhub.prePuller.extraTolerations` |  | `[]` |
| `jupyterhub.prePuller.hook.enabled` |  | `true` |
| `jupyterhub.prePuller.hook.pullOnlyOnChanges` |  | `true` |
| `jupyterhub.prePuller.hook.image.name` |  | `"jupyterhub/k8s-image-awaiter"` |
| `jupyterhub.prePuller.hook.image.tag` |  | `"1.0.1"` |
| `jupyterhub.prePuller.hook.image.pullPolicy` |  | `null` |
| `jupyterhub.prePuller.hook.image.pullSecrets` |  | `[]` |
| `jupyterhub.prePuller.hook.containerSecurityContext.runAsUser` | nobody user | `65534` |
| `jupyterhub.prePuller.hook.containerSecurityContext.runAsGroup` | nobody group | `65534` |
| `jupyterhub.prePuller.hook.containerSecurityContext.allowPrivilegeEscalation` |  | `false` |
| `jupyterhub.prePuller.hook.podSchedulingWaitDuration` |  | `10` |
| `jupyterhub.prePuller.hook.nodeSelector` |  | `{}` |
| `jupyterhub.prePuller.hook.tolerations` |  | `[]` |
| `jupyterhub.prePuller.hook.resources` |  | `{}` |
| `jupyterhub.prePuller.hook.serviceAccount.annotations` |  | `{}` |
| `jupyterhub.prePuller.continuous.enabled` |  | `true` |
| `jupyterhub.prePuller.pullProfileListImages` |  | `true` |
| `jupyterhub.prePuller.extraImages` |  | `{}` |
| `jupyterhub.prePuller.pause.containerSecurityContext.runAsUser` | nobody user | `65534` |
| `jupyterhub.prePuller.pause.containerSecurityContext.runAsGroup` | nobody group | `65534` |
| `jupyterhub.prePuller.pause.containerSecurityContext.allowPrivilegeEscalation` |  | `false` |
| `jupyterhub.prePuller.pause.image.name` |  | `"k8s.gcr.io/pause"` |
| `jupyterhub.prePuller.pause.image.tag` | https://console.cloud.google.com/gcr/images/google-containers/GLOBAL/pause?gcrImageListsize=30 | `"3.2"` |
| `jupyterhub.prePuller.pause.image.pullPolicy` |  | `null` |
| `jupyterhub.prePuller.pause.image.pullSecrets` |  | `[]` |
| `jupyterhub.ingress.enabled` |  | `false` |
| `jupyterhub.ingress.annotations` |  | `{}` |
| `jupyterhub.ingress.hosts` |  | `[]` |
| `jupyterhub.ingress.pathSuffix` |  | `null` |
| `jupyterhub.ingress.tls` |  | `[]` |
| `jupyterhub.cull.enabled` |  | `true` |
| `jupyterhub.cull.users` |  | `false` |
| `jupyterhub.cull.removeNamedServers` |  | `false` |
| `jupyterhub.cull.timeout` |  | `3600` |
| `jupyterhub.cull.every` |  | `600` |
| `jupyterhub.cull.concurrency` |  | `10` |
| `jupyterhub.cull.maxAge` |  | `0` |
| `jupyterhub.debug.enabled` |  | `false` |
| `jupyterhub.global.safeToShowValues` |  | `false` |
| `dask-gateway.gateway.replicas` |  | `1` |
| `dask-gateway.gateway.annotations` |  | `{}` |
| `dask-gateway.gateway.resources` |  | `{}` |
| `dask-gateway.gateway.loglevel` |  | `"INFO"` |
| `dask-gateway.gateway.image.name` |  | `"daskgateway/dask-gateway-server"` |
| `dask-gateway.gateway.image.tag` |  | `"0.9.0"` |
| `dask-gateway.gateway.image.pullPolicy` |  | `"IfNotPresent"` |
| `dask-gateway.gateway.imagePullSecrets` |  | `[]` |
| `dask-gateway.gateway.service.annotations` |  | `{}` |
| `dask-gateway.gateway.auth.simple.password` |  | `null` |
| `dask-gateway.gateway.auth.kerberos.keytab` |  | `null` |
| `dask-gateway.gateway.auth.jupyterhub.apiToken` |  | `null` |
| `dask-gateway.gateway.auth.jupyterhub.apiUrl` |  | `null` |
| `dask-gateway.gateway.auth.custom.class` |  | `null` |
| `dask-gateway.gateway.auth.custom.options` |  | `{}` |
| `dask-gateway.gateway.livenessProbe.enabled` |  | `true` |
| `dask-gateway.gateway.livenessProbe.initialDelaySeconds` |  | `5` |
| `dask-gateway.gateway.livenessProbe.timeoutSeconds` |  | `2` |
| `dask-gateway.gateway.livenessProbe.periodSeconds` |  | `10` |
| `dask-gateway.gateway.livenessProbe.failureThreshold` |  | `6` |
| `dask-gateway.gateway.readinessProbe.enabled` |  | `true` |
| `dask-gateway.gateway.readinessProbe.initialDelaySeconds` |  | `5` |
| `dask-gateway.gateway.readinessProbe.timeoutSeconds` |  | `2` |
| `dask-gateway.gateway.readinessProbe.periodSeconds` |  | `10` |
| `dask-gateway.gateway.readinessProbe.failureThreshold` |  | `3` |
| `dask-gateway.gateway.backend.image.name` |  | `"daskgateway/dask-gateway"` |
| `dask-gateway.gateway.backend.image.tag` |  | `"0.9.0"` |
| `dask-gateway.gateway.backend.image.pullPolicy` |  | `"IfNotPresent"` |
| `dask-gateway.gateway.backend.namespace` |  | `null` |
| `dask-gateway.gateway.backend.environment` |  | `null` |
| `dask-gateway.gateway.backend.scheduler.extraPodConfig` |  | `{}` |
| `dask-gateway.gateway.backend.scheduler.extraContainerConfig` |  | `{}` |
| `dask-gateway.gateway.backend.scheduler.cores.request` |  | `null` |
| `dask-gateway.gateway.backend.scheduler.cores.limit` |  | `null` |
| `dask-gateway.gateway.backend.scheduler.memory.request` |  | `null` |
| `dask-gateway.gateway.backend.scheduler.memory.limit` |  | `null` |
| `dask-gateway.gateway.backend.worker.extraPodConfig` |  | `{}` |
| `dask-gateway.gateway.backend.worker.extraContainerConfig` |  | `{}` |
| `dask-gateway.gateway.backend.worker.cores.request` |  | `null` |
| `dask-gateway.gateway.backend.worker.cores.limit` |  | `null` |
| `dask-gateway.gateway.backend.worker.memory.request` |  | `null` |
| `dask-gateway.gateway.backend.worker.memory.limit` |  | `null` |
| `dask-gateway.gateway.nodeSelector` |  | `{}` |
| `dask-gateway.gateway.affinity` |  | `{}` |
| `dask-gateway.gateway.tolerations` |  | `[]` |
| `dask-gateway.gateway.extraConfig` |  | `{}` |
| `dask-gateway.controller.enabled` |  | `true` |
| `dask-gateway.controller.annotations` |  | `{}` |
| `dask-gateway.controller.resources` |  | `{}` |
| `dask-gateway.controller.imagePullSecrets` |  | `[]` |
| `dask-gateway.controller.loglevel` |  | `"INFO"` |
| `dask-gateway.controller.completedClusterMaxAge` |  | `86400` |
| `dask-gateway.controller.completedClusterCleanupPeriod` |  | `600` |
| `dask-gateway.controller.backoffBaseDelay` |  | `0.1` |
| `dask-gateway.controller.backoffMaxDelay` |  | `300` |
| `dask-gateway.controller.k8sApiRateLimit` |  | `50` |
| `dask-gateway.controller.k8sApiRateLimitBurst` |  | `100` |
| `dask-gateway.controller.image.name` |  | `"daskgateway/dask-gateway-server"` |
| `dask-gateway.controller.image.tag` |  | `"0.9.0"` |
| `dask-gateway.controller.image.pullPolicy` |  | `"IfNotPresent"` |
| `dask-gateway.controller.nodeSelector` |  | `{}` |
| `dask-gateway.controller.affinity` |  | `{}` |
| `dask-gateway.controller.tolerations` |  | `[]` |
| `dask-gateway.traefik.replicas` |  | `1` |
| `dask-gateway.traefik.annotations` |  | `{}` |
| `dask-gateway.traefik.resources` |  | `{}` |
| `dask-gateway.traefik.image.name` |  | `"traefik"` |
| `dask-gateway.traefik.image.tag` |  | `"2.1.3"` |
| `dask-gateway.traefik.additionalArguments` |  | `[]` |
| `dask-gateway.traefik.loglevel` |  | `"WARN"` |
| `dask-gateway.traefik.dashboard` |  | `false` |
| `dask-gateway.traefik.service.annotations` |  | `{}` |
| `dask-gateway.traefik.service.spec` |  | `{}` |
| `dask-gateway.traefik.service.ports.web.port` |  | `80` |
| `dask-gateway.traefik.service.ports.web.nodePort` |  | `null` |
| `dask-gateway.traefik.service.ports.tcp.port` |  | `"web"` |
| `dask-gateway.traefik.service.ports.tcp.nodePort` |  | `null` |
| `dask-gateway.traefik.nodeSelector` |  | `{}` |
| `dask-gateway.traefik.affinity` |  | `{}` |
| `dask-gateway.traefik.tolerations` |  | `[]` |
| `dask-gateway.rbac.enabled` |  | `true` |
| `dask-gateway.rbac.controller.serviceAccountName` |  | `null` |
| `dask-gateway.rbac.gateway.serviceAccountName` |  | `null` |
| `dask-gateway.rbac.traefik.serviceAccountName` |  | `null` |





