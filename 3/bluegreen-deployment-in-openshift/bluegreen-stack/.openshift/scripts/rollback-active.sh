#!/bin/bash
set -o allexport
source env.properties
set +o allexport

oc project ${PROJECT}
# Determine active color and old color, and consequently active deployment and old deployment names.
activeServiceName=$(oc get route ${ACTIVE_ROUTE} -o json | jq -r .spec.to.name)
activeColor=$(echo ${activeServiceName} | grep -o '[^-]*$')
oldColor=""

if [[ "${activeColor}" == *"blue"* ]];
then
    oldColor="green"
else
    oldColor="blue"
fi

activeDeploymentName=${APP_NAME}-${activeColor}
oldDeploymentName=${APP_NAME}-${oldColor}


# Scale up old app by number of pods equal to the new app.
numberOfPods=$(oc get deployment/${activeDeploymentName} -o json | jq .status.replicas)
echo "Scaling up ${oldDeploymentName} to ${numberOfPods} replicas"
oc scale --replicas=${numberOfPods} deployment/${oldDeploymentName} 

sleep 10s
# Switch active route and preview route to old app.
newServiceName=${APP_NAME}-${oldColor}
echo "Patching routes ${ACTIVE_ROUTE} and ${PREVIEW_ROUTE} to point to service: ${newServiceName}"
oc patch route ${ACTIVE_ROUTE} -p '{"spec":{"to":{"name":"'"${newServiceName}"'"}}}' 
oc patch route ${PREVIEW_ROUTE} -p '{"spec":{"to":{"name":"'"${newServiceName}"'"}}}' 

sleep 10s
# Scale down new app which has become old app.
echo "Scaling down ${activeDeploymentName} to 0 replicas"
oc scale --replicas=0 deployment/${activeDeploymentName} 
