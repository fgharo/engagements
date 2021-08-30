# Integration via One Time Vault Server setup and Vault Agent

Prereqs:
Run these steps before doing one of the samples in this folder.


1. A Kubernetes Cluster / I am using CRC Openshift

2. A Vault Server is up and running and the address is known ahead of time. I am running one on on CRC Openshift. Make sure to 
have VAULT_ADDR environment variable setup.
```
export VAULT_ADDR=http://vault-fake-external-vault.apps-crc.testing
```

3. Logged into both openshift and vault in your local computer:
```
oc login ...
vault login 
```

4. A read policy is configured before hand for the soon to come role called example.
Validate that the policies has the correct information
```
vault policy write myapp-kv-ro - <<EOF
path "secret/data/myapp/*" {
    capabilities = ["read", "list"]
}
EOF
```

1. A namespace called vault-consumer exists and a service account called vault-auth has been prepared with system:auth-delegator cluster role.

```
oc new-project vault-consumer
oc create sa vault-auth
oc apply -f vault-auth-service-account-cluster-role-binding.yaml
```


References:

https://learn.hashicorp.com/tutorials/vault/agent-kubernetes?in=vault/kubernetes