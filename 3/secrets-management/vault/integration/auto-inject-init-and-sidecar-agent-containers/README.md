In this section we will use a Vault Agent Injector Service to auto-inject init and sidecar vault agents
to pods/deployments/etc that have the appropriate annotations. Also the Vault Agent Injector and the init,side car containers will 
call off to an external Vault Server.

Prereqs:
1. You have done the steps in the common ../README.md
2. You have done setup of the kubernetes auth method, role, and sample data from project sample ../manual-explicit-init-and-sidecar-agent-containers
3. Your in the right project called vault-consumer `oc project vault-consumer`. As all the kubernetes resources will be created in that namespace.
4. Helm is installed.
```
$ helm version
version.BuildInfo{Version:"v3.6.3", GitCommit:"d506314abfb5d21419df8c7e7e68012379db2354", GitTreeState:"clean", GoVersion:"go1.16.5"}
```

# Integrating with External Vault Server

1. Deploy service and endpoints to address an external Vault
```
oc apply -f external-vault.yaml
```

2. Validate by original podspec that points at ip address can also call the external-vault service.
```
oc apply -f podspec-manual-auth.yaml
oc exec devwebapp -- curl -s http://external-vault:8200/v1/sys/seal-status | jq
{
  "type": "shamir",
  "initialized": true,
  "sealed": false,
  "t": 1,
  "n": 1,
  "progress": 0,
  "nonce": "",
  "version": "1.8.2",
  "migration": false,
  "cluster_name": "vault-cluster-cb74b66b",
  "cluster_id": "b2fbfa99-dcf1-3b61-a7c0-cdc7227d9ec8",
  "recovery_seal": false,
  "storage_type": "inmem"
}
```


3. Install the Vault Helm chart with only Vault Agent Injector Service pointing to external Vault Server

```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault --set "injector.externalVaultAddr=http://external-vault:8200"
```

Watch out the Deployment of vault-agent-injector requests to run with a user id of 100. The pod will fail to come up.
You should see this error message below as Openshift runs pods with random userid and will not respect the securityContext.runAsUser
request unless the serviceAccountName vault-agent-injector has the proper securitycontextcontstraint. 
```
Generated from replicaset-controller 

Error creating: pods "vault-agent-injector-77598c6cf9-" is forbidden: unable to validate against any security context constraint: [spec.containers[0].securityContext.runAsUser: Invalid value: 100: must be in the ranges: [1000620000, 1000629999]]
```


We need a cluster admin to apply the security context constraint. Scale the deployment down to zero. Then apply the scc of anyuid below to that serviceaccount. Then scale back up.
```
oc adm policy add-scc-to-user anyuid -z vault-agent-injector
```

Finally validate the injector injects agents into podspec successfully. 
```
oc apply -f podspec.yaml

oc exec -it pod/devwebapp-with-annotations -c app -- cat /vault/secrets/myapp-config
data: map[password:suP3rsec(et! ttl:30s username:appuser]
metadata: map[created_time:2021-08-31T07:18:36.447540457Z deletion_time: destroyed:false version:2]

```


References:

https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault?in=vault/kubernetes
