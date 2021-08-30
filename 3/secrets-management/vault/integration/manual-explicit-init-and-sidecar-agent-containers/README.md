Prereqs - You have read the common ../README.md
## Integrating Vault Server


### One time setup in a Single Openshift Namespace/Project
1. Make sure the vault server has kubernetes auth method enabled and configured properly.


Set up some environment variables that will have the information for setting up the kubernetes authentication method
on the vault server.

```
# Helper environment variable. Make sure there is only one name in this environment variable.
# When you created the sa vault-auth, a secret was automatically created for you. 
# Make sure you don't assign this to the docker secret.
export VAULT_SA_JWT_AUTH_TOKEN_SECRET_NAME=$(oc get sa vault-auth --output jsonpath="{.secrets[0]['name']}")

# This infor used to access the TokenReview API
export VAULT_SA_JWT_AUTH_TOKEN=$(oc get secret $VAULT_SA_JWT_AUTH_TOKEN_SECRET_NAME --output 'go-template={{ .data.token }}' | base64 --decode)

export K8S_HOST=$(oc config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.server}')

# Putting this in an environment variable happens to remove all the newlines and corrupt the CA cert. Instead we will refer to it as a file.
oc config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode > certs.pem
```

Configure the kubernetes authentication method on the Vault server. 

```
vault auth enable kubernetes

vault write auth/kubernetes/config \
    token_reviewer_jwt="$VAULT_SA_JWT_AUTH_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="@certs.pem"

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


3. Run the pod and test out the endpoint

Setup the init and sidecar agent configuration file:
```
oc apply -f configmap.yaml
```

Run the test pod with a route that we can click on to see the rendering of the secret values.
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