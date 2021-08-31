Prereqs - You have read the common ../README.md
## Integrating Vault Server


### One time setup in a Single Openshift Namespace/Project
1. Make sure the vault server has kubernetes auth method enabled and configured properly.


Set up some environment variables that will have the information for setting up the kubernetes authentication method
on the vault server.

```
# Helper environment variable. 
# Make sure there is only one name in this environment variable.
# When you created the sa vault-auth, a secret was automatically created for you. 
# Grab the non dockercfg
oc get sa vault-auth -o yaml
...
secrets:
- name: vault-auth-dockercfg-fjd2s
- name: vault-auth-token-v5hqh

export VAULT_SA_JWT_AUTH_TOKEN_SECRET_NAME=vault-auth-token-v5hqh

# This info is used by the vault server to access the TokenReview API
export VAULT_SA_JWT_AUTH_TOKEN=$(oc get secret $VAULT_SA_JWT_AUTH_TOKEN_SECRET_NAME --output 'go-template={{ .data.token }}' | base64 --decode)

export K8S_HOST=$(oc config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.server}')

export SA_CA_CRT=$(oc get secret $VAULT_SA_JWT_AUTH_TOKEN_SECRET_NAME --output jsonpath='{.data.ca\.crt}' | base64 --decode)
```


Configure the kubernetes authentication method on the Vault server. 

```
vault auth enable kubernetes

vault write auth/kubernetes/config \
    token_reviewer_jwt="$VAULT_SA_JWT_AUTH_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$SA_CA_CRT"

vault write auth/kubernetes/role/example \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=vault-consumer \
    policies=myapp-kv-ro \
    ttl=24h
```



Validate that the authentication method has correct configuration.
```
vault read auth/kubernetes/config
Key                       Value
---                       -----
disable_iss_validation    false
disable_local_ca_jwt      false
issuer                    n/a
kubernetes_ca_cert        ...
-----BEGIN CERTIFICATE-----
MIIDWzCCAkOgAwIBAgIIRXs6ZYZzD14wDQYJKoZIhvcNAQELBQAwJjEkMCIGA1UE
...
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDDDCCAfSgAwIBAgIBATANBgkqhkiG9w0BAQsFADAmMSQwIgYDVQQDDBtpbmdy
ZXNzLW9wZXJhdG9yQDE2MjE0ODYyODcwHhcNMjEwNTIwMDQ1MTI2WhcNMjMwNTIw
...
kubernetes_host           https://api.crc.testing:6443
...
```

Validate that the role setup has correct configuration.
```
vault read auth/kubernetes/role/example
Key                                 Value
---                                 -----
bound_service_account_names         [vault-auth]
bound_service_account_namespaces    [vault-consumer]
policies                            [myapp-kv-ro]
...
```

2. Make sure there is some sample data on the Vault server to consume for the demo.

```
vault kv put secret/myapp/config \
    username='appuser' \
    password='suP3rsec(et!' \
    ttl='30s'
```


3. Validate in two different ways:
CAUTION: Make sure the VAULT_ADDR environment variable is set to the correct value in the Pod yaml.




Way 1: Run the pod and manually authenticate by calling the vault server via curl. 
```
oc apply -f podspec-manual-auth.yaml
```

Open the terminal to the pod and issue a curl command.
```
oc debug pod/devwebapp

# KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
# curl --request POST  --data '{"jwt": "'"$KUBE_TOKEN"'", "role": "example"}'  $VAULT_ADDR/v1/auth/kubernetes/login
{"request_id":"46486d42-faac-7eb4-8b9a-7057592571b4","lease_id":"","renewable":false,"lease_duration":0,"data":null,"wrap_info":null,"warnings":null,"auth":{"client_token":"s.dTSO3UothqCCbWA0PoTwuWZf","accessor":"baTd7ASokVhAFHlpnGZh6mF5","policies":["default","myapp-kv-ro"],"token_policies":["default","myapp-kv-ro"],"metadata":{"role":"example","service_account_name":"vault-auth","service_account_namespace":"vault-consumer","service_account_secret_name":"vault-auth-token-v5hqh","service_account_uid":"08da5799-4ddf-4006-9bb7-90990388a16d"},"lease_duration":86400,"renewable":true,"entity_id":"c5d2ca35-6aa8-2581-24be-00a397c860fc","token_type":"service","orphan":true}}
```



Way 2: Run the pod configured with the agents and test out the endpoint
Setup the init and sidecar agent configuration file:
```
oc apply -f configmap.yaml
```

Run the test pod with a route that we can click on to see the rendering of the secret values.

CAUTION: if tls certificates are bad and you need to quickly just test out the integration, you can turn off the tls verification by setting environment variable VAULT_SKIP_VERIFY on the pod specs environment variable list. This can also be set on the vault-agent-config.hcl file defined in the configmap applied earlier. Please refer to links below for full agent configuration settings.
```
oc apply -f podspec.yaml
oc apply -f svc.yaml
oc apply -f route.yaml
```

If you hit the route in a web browser you should see something like the following:

<html>
    <body>
        <p>Some secrets:</p>
        <ul>
        <li><pre>username: appuser</pre></li>
        <li><pre>password: suP3rsec(et!</pre></li>
        </ul>
    </body>
</html>


Special Notes:
Notice that this is limited to the role that was setup in the namespace vault-consumer for sa vault-auth existing in that namespace. If we try to do this in another namespace with a different service account this will fail.



References:

https://learn.hashicorp.com/tutorials/vault/agent-kubernetes?in=vault/kubernetes

https://cloud.redhat.com/blog/integrating-hashicorp-vault-in-openshift-4

https://www.vaultproject.io/docs/agent
