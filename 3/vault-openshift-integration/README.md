# Integration with External Vault Server setup and CRC Openshift

Prereqs:
Run these steps before doing one of the samples in this folder.


1. A Kubernetes Cluster. I installed CRC Openshift and configured it to talk to host system network. Please see links below.
```
crc config set network-mode user
crc config set host-network-access true
crc cleanup
crc setup
crc start
```

2. A Vault Server is up and running on the same host as CRC Openshift but external to it. Please see links below.

Make sure to have VAULT_ADDR environment variable setup for vault login.
```
vault server -dev -dev-root-token-id root -dev-listen-address 0.0.0.0:8200
==> Vault server configuration:

             Api Address: http://0.0.0.0:8200
                     Cgo: disabled
         Cluster Address: https://0.0.0.0:8201
              Go Version: go1.16.7
              Listener 1: tcp (addr: "0.0.0.0:8200", cluster address: "0.0.0.0:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level: info
                   Mlock: supported: true, enabled: false
           Recovery Mode: false
                 Storage: inmem
                 Version: Vault v1.8.2
             Version Sha: aca76f63357041a43b49f3e8c11d67358496959f
...
export VAULT_ADDR=http://192.168.1.100:8200
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

5. A namespace called vault-consumer exists and a service account called vault-auth has been prepared with system:auth-delegator cluster role.

```
oc new-project vault-consumer
oc create sa vault-auth
oc apply -f manual-explicit-init-and-sidecar-agent-containers/service-account-cluster-role-binding.yaml 
```


References:

https://learn.hashicorp.com/tutorials/vault/agent-kubernetes?in=vault/kubernetes

https://crc.dev/crc/#installation_gsg

https://learn.hashicorp.com/tutorials/vault/kubernetes-openshift?in=vault/kubernetes
