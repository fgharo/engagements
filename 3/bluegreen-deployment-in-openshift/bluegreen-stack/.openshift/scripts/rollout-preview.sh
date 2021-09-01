#!/bin/bash
set -o allexport
source env.properties
set +o allexport

oc project ${PROJECT}
version=$(echo "$1" | cut -d':' -f 2)
firstDeployment=$(oc get route ${ACTIVE_ROUTE}   2>&1 >/dev/null)

# If this is very first deployment then there are no consumers, both previewRoute and activeRoute can point to the same application.
# We will adopt a convention of starting with color blue
if [[ "${firstDeployment}" == *"NotFound"* ]]; 
then
  echo "This will be the first deployment"
  cd ../base
  kustomize edit set image "${APP_NAME}=$1"
  kustomize edit add label "app.kubernetes.io/name":"${APP_NAME}"
  kustomize edit add label "app.kubernetes.io/version":"${version}"
  kustomize edit add label "app.color":"blue"
  kustomize edit set namesuffix -- -blue
  kustomize build | oc apply -f -
  oc apply -f ../helperroutes/activeRoute.yaml 
  oc apply -f ../helperroutes/previewRoute.yaml 

# We have deployed before, preview kubernetes resources should reflect the opposite color of the active deployments color.
else
  activeColor=$(oc get route ${ACTIVE_ROUTE} -o json   | jq -r .spec.to.name | grep -o '[^-]*$')
  previewColor=""

  if [[ "${activeColor}" == "blue" ]];
  then
    previewColor="green"
  else
    previewColor="blue"
  fi

  echo "${activeColor} already deployed"
  echo "Get ready to deploy ${previewColor} to preview status."
  cd ../base
  kustomize edit set image "${APP_NAME}=$1"
  kustomize edit add label "app.kubernetes.io/name":"${APP_NAME}"
  kustomize edit add label "app.kubernetes.io/version":"${version}"
  kustomize edit add label "app.color":"${previewColor}"
  kustomize edit set namesuffix -- -${previewColor}
  previewServiceName=${APP_NAME}-${previewColor}
  # editting the labels earlier results in updating the matchLabels of the yaml during the apply but these are immutable.
  # After the second deployment, the yamls will be out there and an error will be caused preventing
  # a new deployment. Make sure the resources are not present first. 
  oc delete all -l "app.kubernetes.io/name"="${APP_NAME}" -l "app.color"="${previewColor}" --ignore-not-found=true 
  sleep 10s
  kustomize build | oc apply -f -
  oc patch route ${PREVIEW_ROUTE} -p '{"spec":{"to":{"name":"'"${previewServiceName}"'"}}}' 

fi

