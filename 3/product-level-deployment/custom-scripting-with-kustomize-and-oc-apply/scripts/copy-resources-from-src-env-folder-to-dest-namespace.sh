#!/bin/bash


env=$1
destNamespace=$2

projectExistsOutput=$(oc get project ${destNamespace} 2>&1 >/dev/null)


set -e

if [[ "${projectExistsOutput}" == *"(NotFound)"* ]]; then
    echo ${projectExistsOutput}
    echo
    echo "Creating destination namespace ${destNamespace}"
    oc new-project ${destNamespace}
    sleep 5s
else
    oc project ${destNamespace}
fi

cd ..
for dir in deployConfig/*; do
    echo
    echo "Deploying resources from ${dir}/${env} to namespace ${destNamespace}"
    cd ${dir}/${env}
    kustomize edit set namespace ${destNamespace}
    kustomize build | oc apply -f -
    cd -
    echo "Sleeping for 5 seconds"
    echo
    sleep 5s
done