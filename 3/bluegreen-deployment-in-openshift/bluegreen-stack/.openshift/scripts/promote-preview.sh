#!/bin/bash
set -o allexport
source env.properties
set +o allexport


oc project ${PROJECT}
# Point active to preview.
previewServiceName=$(oc get route ${PREVIEW_ROUTE} -o json | jq -r .spec.to.name)
oc patch route ${ACTIVE_ROUTE} -p '{"spec":{"to":{"name":"'"${previewServiceName}"'"}}}' 
echo ${previewServiceName}

# Scale down old application.
newColor=$(echo ${previewServiceName} | grep -o '[^-]*$')
oldColor=""

if [[ "${newColor}" == *"blue"* ]];
then
    oldColor="green"
else
    oldColor="blue"
fi

oc scale --replicas=0 deployment/${APP_NAME}-${oldColor} 
