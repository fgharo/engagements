#!/bin/bash

for namespace in $(oc get namespaces -o jsonpath='{.items[*].metadata.name}' | xargs); do
  if [[ "${namespace}" =~ openshift.* ]] || [[ "${namespace}" =~ kube.* ]] || [[ "${namespace}" =~ default ]]; then
    oc patch namespace/${namespace} -p='{"metadata":{"labels":{"admission.gatekeeper.sh/ignore":"true"}}}'
  else
    # Probably a users project, so leave it alone
    echo "Skipping: ${namespace}"
  fi
done