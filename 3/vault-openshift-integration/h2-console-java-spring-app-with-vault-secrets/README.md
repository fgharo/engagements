# Vault Openshift Integration with Spring Boot app and Consul Template Markup
This project is to explore and demo integrating vault with a spring boot app using consul template markup, vault agent, an agent configuration file, and
kubernetes resources expressing the agent as an init container in a kubernetes deployment.


Prereqs:
1. You have ran setup as described in parent ../README.md and sample ../manual-explicit-init-and-sidecar-agent-containers.


## Main Steps:

1. There is some sample secret in the vault server:
```
vault kv put secret/myapp/vault-demo-config-secret     username='appuser'     password='suP3rsec(et!'     ttl='30s'
```

2. Make sure the app container image is accessible. For me, I have mine hosted at quay.io/user15/vault-demo:latest. The value is
configured in the .openshift/base/deployment.yaml file.

3. Make sure the namespace you would like to deploy this application to has its name configured in the Vault kubernetes auth method configuration role called example. For my purposes I used the namespace dev. So I made sure that was configured on the vault server.
```
vault write auth/kubernetes/role/example  \
    bound_service_account_names=vault-auth   \
    # Make sure not to erase other namespaces that were configured in the past. Probably better to use ui for this part
    # If there are a lot of namespaces.
    bound_service_account_namespaces=vault-consumer,dev  \    
    policies=myapp-kv-ro    \
    ttl=24h
``` 

4. Make sure there is a service account called vault-auth in the namespace where we are deploying this application.
```
oc create sa vault-auth -n dev
```    

5. Deploy the application to CRC Openshift.

```
cd .openshift/base
kustomize edit set namespace dev
kustomize build | oc apply -f - -n dev
```

6. Testing out that the secret got injected.

a. Get the application route.
```
oc get route -n dev
```
b. Visit the route in a browser with the path /h2-console

c. Login with JDBC URL as jdbc:h2:mem:testdb, username as h2user and password as suP3rsec(et! (Or with whatever value you created in step 1. above.)

# Running this application locally.

## Building the application
`mvn clean install`


## Running the application locally.

Using environment variables:

```
export TEMP_VAULT_TOKEN=s.TGn49lJkBVUWyWlel19jPGad
java -jar target/vault-demo-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev
```

OR

Using pure command line arguments:

`java -jar target/vault-demo-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev --TEMP_VAULT_TOKEN=s.TGn49lJkBVUWyWlel19jPGad`

If everything went fine you should see these logs in the startup log output:

```
2020-11-17 09:29:10.281  INFO 1805860 --- [           main] c.e.vaultdemo.VaultDemoApplication       : Vault value injected via Environment class vault-demo.made.up.property: Made stuff up!!!
2020-11-17 09:29:10.281  INFO 1805860 --- [           main] c.e.vaultdemo.VaultDemoApplication       : Vault value injected via Value annotation vault-demo.made.up.property: Made stuff up!!!
```

## Using the application
If set up went fine then hit localhost:8080/h2-console and login with JDBC URL as jdbc:h2:mem:testdb username as h2user and password as h2pass. You should have access to the h2 in memory db via the h2 console.


### Reference Documentation
For further reference, please consider the following sections:

* [Official Apache Maven documentation](https://maven.apache.org/guides/index.html)
* [Spring Boot Maven Plugin Reference Guide](https://docs.spring.io/spring-boot/docs/2.3.5.RELEASE/maven-plugin/reference/html/)
* [Create an OCI image](https://docs.spring.io/spring-boot/docs/2.3.5.RELEASE/maven-plugin/reference/html/#build-image)

