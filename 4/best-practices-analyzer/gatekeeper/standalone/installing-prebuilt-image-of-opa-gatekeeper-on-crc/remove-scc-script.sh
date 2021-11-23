#!/bin/bash

oc patch Deployment/gatekeeper-audit --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations"}]' -n gatekeeper-system
oc patch Deployment/gatekeeper-controller-manager --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations"}]' -n gatekeeper-system
oc patch Deployment/gatekeeper-audit --type json --patch '[{ "op": "remove", "path": "/spec/template/spec/containers/0/securityContext" }]' -n gatekeeper-system
oc patch Deployment/gatekeeper-controller-manager --type json --patch '[{ "op": "remove", "path": "/spec/template/spec/containers/0/securityContext" }]' -n gatekeeper-system
