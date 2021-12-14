#!/bin/bash
echo "["
for namespace in $(oc get namespaces -o jsonpath='{.items[*].metadata.name}' | xargs); do

  if [[ "${namespace}" =~ openshift.* ]] || [[ "${namespace}" =~ kube.* ]]; then
    # oc patch namespace/${namespace} -p='{"metadata":{"labels":{"admission.gatekeeper.sh/ignore":"true"}}}'
    # Probably a users project, so leave it alone
    echo "\"${namespace}\","
  fi
done
echo "]"
