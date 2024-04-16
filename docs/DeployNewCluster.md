# Deploying a Worker Cluster from the Staging Cluster

### In this doc there will be the steps needed to deploy a child cluster off of a staging cluster.
(This expects that you have been given access to a Staging Cluster)

## Steps for the new cluster 
(from a machine that can push to the github repo)

## 1. Clone the github repo and switch to a new branch

```
git clone git@github.com:stfc/cloud-deployed-apps.git
git swtich -c <new-branch-name> origin/<new-branch-name>
```

## 2. Add the following directories/files

```
clusters/<your-cluster-name>/overrides/infra/deployment.yaml
clusters/<your-cluster-name>/app-values.yaml
clusters/<your-cluster-name>/argocd-values.yaml
```
## 3. Create a secret for the cluster to use
From the staging cluster, create a directory to work in
3a. Create a clouds.yaml in the directory (An application credential file for target project)
3b. Create a file ca.cert.txt with the certificate here - https://github.com/stfc/cloud-capi-values/blob/master/values.yaml#L6-L130
#Ensure you've only copied the two certs from -----BEGIN CERTIFICATE----- to -----END CERTIFICATE-----

3c. Lastly run `kubectl create secret generic <secret-name> --from-file=cacert=./cacert.txt --from-file=clouds.yaml=./clouds.yaml -n clusters` to create the secret

## 4. Contents for deployment.yaml

```
openstack-cluster:
  controlPlane:
    machineCount: 3

  nodeGroups:
    - name: default-md-0
      machineCount: 2

  nodeGroupDefaults:
    machineFlavor: l3.tiny

  cloudCredentialsSecretName: <cloud-creds-secret-name>

  addons:
    ingress:
      enabled: true
      nginx:
        release:
          values:
            controller:
              service:
                loadBalancerIP: "<float-ip-in-target-project>"
```

## 5. Contents for app-values.yaml

```
global:
  ### name of the cluster 
  ### MUST MATCH THE DIRECTORY NAME
  
  clusterName: <your-cluster-name> #Same as in step 2

  spec:
    source:
      targetRevision: `<your-branch>`

      # change this if you're using a fork
      repoURL: https://github.com/stfc/cloud-deployed-apps.git 

      # namespace where the argocd applications will be installed to 
      namespace: argocd
```

## 6. Contents for argocd-values.yaml
### The domain name is set by you, if you are testing a good name to use is "test.argocd.stfc.nubes.ac.uk" and you will have to add it to your etc hosts link for this
`https://www.wikihow.com/Edit-the-Hosts-File-on-Windows#:~:text=1%20Open%20the%20Start%20menu%2C%20and%20click%20%22Computer%22.,the%20file%20directly%20to%20your%20%22etc%22...%20See%20More`
  
```
argo-cd:
  global: 
    # default is argocd.example.com
    domain: "<your-domain-name>" 
```

## 7. Add the cluster into the staging cluster
inside `clusters/staging-management-cluster/infra-values.yaml`

Add a section like above sections using template:
```
  - name: <your-cluster-name>
    disableAutomated: false
    chartName: capi
    namespace: clusters
    additionalValueFiles:
      - clusters/<your-cluster-name>/overrides/infra/deployment.yaml
```

## 8. Once these changes are merged then the staging cluster will start to spin up your new cluster

You will then be able to retrieve the kubeconfig for the new cluster once it is spun up

Use `clusterctl describe cluster $CLUSTER_NAME -n clusters` to check the status of the cluster

Use `clusterctl get kubeconfig $CLUSTER_NAME -n clusters > $CLUSTER_NAME.kubeconfig` to output the kubeconfig for the cluster

