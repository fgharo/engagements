In this exercise we install policies (constrainttemplate+constraint) from the opa gatekeeper library project and test them when deploying an app to the apps namespace. The specific constraint is to only allow Deployment objects that have replicas defined in a range from 1 to 5 pods.

Prereqs:
1. Opa Gatekeeper has been installed. Run exercise ../installing-prebuilt-image-of-opa-gatekeeper-on-crc
2. The apps namespace exists `oc new-project apps`


## Installing a precanned library Policy (ConstraintTemplate+Constraint)

1. Apply the local kustomization which has been configured to point to the specific replica limits constraint template in the opa gatekeeper library (i.e. github.com/open-policy-agent/gatekeeper-library/library/general/replicalimits)
 and save it to namespace gatekeeper-system.

```
kustomize build . | oc apply -f - -n gatekeeper-system
```

2. Notice when applying a new constraint template gatekeeper-audit logged the following audit object to stdout/stderror:
```
{
  "level": "info",
  "ts": 1637648575.541089,
  "logger": "controller",
  "msg": "constraint",
  "process": "audit",
  "audit_id": "2021-11-23T06:22:35Z",
  "resource kind": "K8sReplicaLimits"
}
```

3. To use/enforce the constraint template from the gatekeeper library a predefined constraint.yaml was designed with a range of 1-5 that is an instantiation of the CRD defined by the template with kind name K8sReplicaLimits. Basically just copied/pasted and tweaked a sample constraint given by the opa gatekeeper library in github folder library/general/replicalimits/samples/replicalimits/

```
oc apply -f constraint.yaml -n gatekeeper-system
```

4. To get constraint templates loaded/installed in gatekeeper-system, query as follows:
```
oc get constrainttemplates -n gatekeeper-system
...
NAME               AGE
k8sreplicalimits   65m
```

5. To get actual enforced constraints loaded/installed in gatekeeper-system query as follows:
```
oc get constraints -n gatekeeper-system
...
NAME             AGE
replica-limits   61m
```


## Test the actual enforced Constraints

1. Deploy an application with replicas out of range (i.e. violate the policy or enforced constraint). The default enforcementAction if not specified is deny.
The admission webhook should reject and the api server should return error without allowing the pods to be deployed.

```
oc apply -f disallowed-deployment.yaml -n apps
...
Error from server ([replica-limits] The provided number of replicas is not allowed for deployment: bluegreen-stack. Allowed ranges: {"ranges": [{"max_replicas": 5, "min_replicas": 1}]}): error when creating "disallowed-deployment.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [replica-limits] The provided number of replicas is not allowed for deployment: bluegreen-stack. Allowed ranges: {"ranges": [{"max_replicas": 5, "min_replicas": 1}]}
```




## Gotchas

1. Deployed app to gatekeeper-system
If you created disallowed-deployment.yaml to gatekeeper-system, then it won't actually get an error from server but instead just log the violation. 

We should also see the following audit object logged to stdout/stderror by gatekeeper audit.
```
{
  "level": "info",
  "ts": 1637649658.5136657,
  "logger": "controller",
  "msg": "The provided number of replicas is not allowed for deployment: bluegreen-stack. Allowed ranges: {\"ranges\": [{\"max_replicas\": 5, \"min_replicas\": 1}]}",
  "process": "audit",
  "audit_id": "2021-11-23T06:40:35Z",
  "event_type": "violation_audited",
  "constraint_group": "constraints.gatekeeper.sh",
  "constraint_api_version": "v1beta1",
  "constraint_kind": "K8sReplicaLimits",
  "constraint_name": "replica-limits",
  "constraint_namespace": "",
  "constraint_action": "deny",
  "resource_group": "apps",
  "resource_api_version": "v1",
  "resource_kind": "Deployment",
  "resource_namespace": "gatekeeper-system",
  "resource_name": "bluegreen-stack"
}
```

Additionally, the status object of the constraint resource will have violations:

```
oc get constraints replica-limits -o yaml
...
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sReplicaLimits
metadata:
    ...
  name: replica-limits
spec:
  match:
    kinds:
    - apiGroups:
      - apps
      kinds:
      - Deployment
  parameters:
    ranges:
    - max_replicas: 5
      min_replicas: 1
...
status:
  auditTimestamp: "2021-11-23T06:44:35Z"
  byPod:
    ...
  totalViolations: 1
  violations:
  - enforcementAction: deny
    kind: Deployment
    message: 'The provided number of replicas is not allowed for deployment: bluegreen-stack. Allowed ranges: {"ranges": [{"max_replicas": 5, "min_replicas": 1}]}'
    name: bluegreen-stack
    namespace: gatekeeper-system
```

Notice this didn't actually enforce the constraint the oc apply went through and I was still able to instantiate a deployment with 6 replicas in the namespace gatekeeper-system. This is because I deployed in the project/namespace gatekeeper-system which has the following labels:
```
  labels:
    admission.gatekeeper.sh/ignore: no-self-managing
    control-plane: controller-manager
    gatekeeper.sh/system: 'yes'
```



References:

https://github.com/open-policy-agent/gatekeeper-library