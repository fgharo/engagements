In this exercise we install OPA Gatekeeper as a standalone application in its own namespace on CRC/Openshift. 



1.

a. Install the kubernetes resources that make up the gatekeeper system. A namespace called gatekeeper-openshift will be created.
```
oc apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.5/deploy/gatekeeper.yaml
```
b. Alternatively we could copy the resources and tweak them locally then apply:
```
curl -SL https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.5/deploy/gatekeeper.yaml > release-3-5-deploy-gatekeeper.yaml
... tweak file with editor.
oc apply -f release-3-5-deploy-gatekeeper.yaml
```

2. To install on Openshift we have to work around certain security context constraints.
```
./remove-scc-script.sh
```

Otherwise we get the following errors:
```
Error creating: pods "gatekeeper-controller-manager-776df47c76-" is forbidden: unable to validate against any security context constraint: [spec.containers[0].securityContext.runAsUser: Invalid value: 1000: must be in the ranges: [1000630000, 1000639999]]
```

```
Error creating: pods "gatekeeper-audit-f694df759-" is forbidden: unable to validate against any security context constraint: [spec.containers[0].securityContext.runAsUser: Invalid value: 1000: must be in the ranges: [1000630000, 1000639999]]
```

3. Before continuing on, make sure certain namespaces are ignored. We don't want gatekeeper to scan openshift-* namespaces for example when enforcing or warning about constraint violations.
```
./mark-ignored-namespaces.sh
```

4. You should see 2 deployments:
```
oc get deployment -n gatekeeper-system
...
NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
gatekeeper-audit                1/1     1            1           7m15s
gatekeeper-controller-manager   3/3     3            3           7m15s
```

References:

https://vikaspogu.dev/posts/opa-gatekeeper-openshift/

https://open-policy-agent.github.io/gatekeeper/website/docs/install/