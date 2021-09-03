# Read Me First
This project is to explore and demo integrating vault with a spring boot app using spring cloud vault.

# Getting Started

Prereqs:
1. Get access to VisTracks vault namespace. https://ot1v30.atlassian.net/wiki/spaces/OMT/pages/943620592/Vault+Integration
2. Login to webui https://omni-dev-vault.aws.omnitracs.com:8200/
3. Add key/value pairs under secrets engine:
vistracks/vault-demo/dev

key: spring.datasource.username value: harry

key: spring.datasource.password value: potter

key: vault-demo.made.up.property value: Made stuff up!!!


## Quick and dirty way to save/use server's self signed ssl certificate in app 
FYI There is already a keystore.jks file in src/main/resources but if it expires you can use these instructions.

1. Either 
    
    a. When opening vault on the browser, Export ssl certificate from chrome as .crt file.
 
    OR
 
    b. issue the following commands:
    
```
export VAULT_CERT_HOST=omni-dev-vault.aws.omnitracs.com
echo false | openssl s_client -connect ${VAULT_CERT_HOST}:8200 -servername ${VAULT_CERT_HOST} -showcerts|openssl x509>/tmp/vault-demo/${VAULT_CERT_HOST}.crt;
```

2. Add the .crt file to a keystore.jks file.

`keytool -importcert -file /tmp/vault-demo/omni-dev-vault.aws.omnitracs.com.crt -keystore /tmp/vault-demo/keystore.jks -alias omni-dev-vault.aws.omnitracs.com`

3. Place keystore.jks in src/main/resources

4. When building with maven below, it should place the keystore.jks in the classpath.

5. When running application below we can either 
    
    a. Reference the keystore.jks by setting properties in boostrap.yml spring.cloud.vault.ssl.trust-store and spring.cloud.vault.ssl.trust-store-password

    OR

    b. Override the command line property when running the jar by appending the following command line arguments:

`--spring.cloud.vault.ssl.trust-store=file:/tmp/vault-demo/keystore.jks --spring.cloud.vault.ssl.trust-store-password=changeit`
  


## Building the application
`mvn clean install`


## Running the application

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
If set up went fine then hit localhost:8080/h2-console and login with JDBC URL as jdbc:h2:mem:testdb username as harry and password as potter. You should have access to the h2 in memory db via the h2 console.


### Reference Documentation
For further reference, please consider the following sections:

* [Official Apache Maven documentation](https://maven.apache.org/guides/index.html)
* [Spring Boot Maven Plugin Reference Guide](https://docs.spring.io/spring-boot/docs/2.3.5.RELEASE/maven-plugin/reference/html/)
* [Create an OCI image](https://docs.spring.io/spring-boot/docs/2.3.5.RELEASE/maven-plugin/reference/html/#build-image)

