#!/bin/bash

for namespace in $(oc get namespaces -o jsonpath='{.items[*].metadata.name}' | xargs); do
  if [[ "${namespace}" =~ openshift.* ]] || [[ "${namespace}" =~ kube.* ]] || [[ "${namespace}" =~ default ]]; then
    echo "\"${namespace}\","
    #oc patch namespace/${namespace} -p='{"metadata":{"labels":{"admission.gatekeeper.sh/ignore":"true"}}}'
  fi
done