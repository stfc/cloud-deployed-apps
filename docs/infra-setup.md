# Infra Setup Steps

This section details some pre/post deployment steps for setting up specific apps

The `capi-infra` chart is used to configure and manage a CAPI cluster itself and any child clusters.  

Cluster API is a tool for provisioning, and operating K8s clusters. We use this tool to run K8s on Openstack. 

We utilise StackHPCs CAPI Chart to do this. See the docs [here](https://github.com/stackhpc/capi-helm-charts). The Chart `openstack-cluster` in this repo is a subchart of `capi-infra`

## Pre-deployment steps

1. Setup Secrets
- see [Deploying clusters](./child-clusters.md) steps 7-8

2. **(Optional)** Add TLS Certs - for CAPI Monitoring

CAPI monitoring (which is enabled by default) requires TLS certs. 

Create a self-signed cert or get one issued. 

To create a self-signed cert:

```bash
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out certificate.crt
```

Then to create a secret from a cert - the secret name is for Prometheus, Alertmanager and Grafana is expected to be `tls-keypair` by default:

```bash
kubectl create secret tls tls-keypair --cert certificate.crt --key privateKey.key -n monitoring-system
```


3. **(Optional)** Enable sending monitoring alerts

Monitoring is enabled by default but will not send alerts out unless configured to. 
In order to turn on alerts - edit the file `clusters/<environment>/<cluster-name>/infra-values.yaml` and add the following

```yaml
stfc-cloud-openstack-cluster:
  openstack-cluster:
    addons:
      monitoring:
        kubePrometheusStack:
          release:
            values:
              defaultRules:
                additionalRuleLabels:
                  cluster: foo # name of cluster
                  env: dev # dev/prod
              alertmanager:
                enabled: true
```


4. **(Optional)** Change the ingress hostnames for monitoring endpoints

```yaml
stfc-cloud-openstack-cluster:
  openstack-cluster:
    addons:
      monitoring:
        kubePrometheusStack:
          release:
            values:
              defaultRules: # see above
                cluster: foo # name of cluster
                env: dev # dev/prod
              alertmanager:
                enabled: true # see above
                ingress:
                  hosts:
                    - <alertmanager-hostname>.nubes.stfc.ac.uk
                  tls:
                    - hosts: 
                      - <alertmanager-hostname>.nubes.stfc.ac.uk
                      secretName: tls-keypair
              prometheus:
                ingress:
                  hosts:
                    - <prometheus-hostname>.nubes.stfc.ac.uk
                  tls:
                    - hosts: 
                      - <prometheus-hostname>.nubes.stfc.ac.uk
                      secretName: tls-keypair
              grafana:
                ingress:
                  hosts:
                    - <grafana-hostname>.nubes.stfc.ac.uk
                  tls:
                    - hosts: 
                      - <grafana-hostname>.nubes.stfc.ac.uk
                      secretName: tls-keypair
``` 
