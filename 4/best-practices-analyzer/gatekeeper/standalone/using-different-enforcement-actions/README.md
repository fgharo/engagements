In this exercise we test out different enforcement actions with constraint templates already given by opa gatekeeper library.

Prereqs:
1. If haven't already, run exercise ../installing-prebuilt-image-of-opa-gatekeeper-on-crc so Opa Gatekeeper is installed.
2. If haven't already, run exercise  ../installing-opa-gatekeeper-library-constraint-templates so Opa Gatekeeper Library ConstraintTemplates and Constraints are available in project gatekeeper-system.


## Try a Warn Enforcement Action

1. Tweak the K8sReplicaLimits resource named replica-limits to have enforcementAction of warn (or dryrun). There are already predefined yamls in the current directory for convenience.

```
oc apply -f warning-constraint.yaml 
...
k8sreplicalimits.constraints.gatekeeper.sh/replica-limits configured
```

## Test the actual warning Constraints

1. Apply earlier disallowed deployment. It should actually let you create it now with a warning instead of denying the request.
```
oc apply -f ../installing-opa-gatekeeper-library-constraint-templates/disallowed-deployment.yaml -n apps
...
W1123 00:59:20.328574 1738111 warnings.go:70] [replica-limits] The provided number of replicas is not allowed for deployment: bluegreen-stack. Allowed ranges: {"ranges": [{"max_replicas": 5, "min_replicas": 1}]}
deployment.apps/bluegreen-stack created
```

2. When we go to describe the constraint we can see a violation on its status object:
```
oc describe constraints replica-limits -n gatekeeper-system
...
Name:         replica-limits
API Version:  constraints.gatekeeper.sh/v1beta1
Kind:         K8sReplicaLimits
...
Spec:
  Enforcement Action:  warn
  Match:
    Kinds:
      API Groups:
        apps
      Kinds:
        Deployment
  Parameters:
    Ranges:
      max_replicas:  5
      min_replicas:  1
Status:
  Audit Timestamp:  2021-11-23T07:59:35Z
  By Pod:
...
  Total Violations:  1
  Violations:
    Enforcement Action:  warn
    Kind:                Deployment
    Message:             The provided number of replicas is not allowed for deployment: bluegreen-stack. Allowed ranges: {"ranges": [{"max_replicas": 5, "min_replicas": 1}]}
    Name:                bluegreen-stack
    Namespace:           apps
Events:                  <none>
```

3. Furthermore we can see gatekeeper audit has logged the following audit object to stdout/stderror:
```
{
  "level": "info",
  "ts": 1637654571.913525,
  "logger": "controller",
  "msg": "The provided number of replicas is not allowed for deployment: bluegreen-stack. Allowed ranges: {\"ranges\": [{\"max_replicas\": 5, \"min_replicas\": 1}]}",
  "process": "audit",
  "audit_id": "2021-11-23T08:02:35Z",
  "event_type": "violation_audited",
  "constraint_group": "constraints.gatekeeper.sh",
  "constraint_api_version": "v1beta1",
  "constraint_kind": "K8sReplicaLimits",
  "constraint_name": "replica-limits",
  "constraint_namespace": "",
  "constraint_action": "warn",
  "resource_group": "apps",
  "resource_api_version": "v1",
  "resource_kind": "Deployment",
  "resource_namespace": "apps",
  "resource_name": "bluegreen-stack"
}
```

References:

https://open-policy-agent.github.io/gatekeeper/website/docs/violations