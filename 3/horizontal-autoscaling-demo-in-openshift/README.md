## Demo 1 - CPU Utilization Average Value: 

Deploying a HorizontalPodAutoscaler that watches 250 millicores CPU Utilization across pods and scales up/down with the default behavior.

1. Create the deployment. Note You may want to change the TZ environment variable to your timezone, so when the
stress test is done later, it prints out a timestamp relative to your time.
```
oc apply -f DeploymentUsingQuayIoImage.yaml -n <The namespace name that you will be creating the deployment and hpa in.>
```


2. Create the horizontalpodautoscaler (hpa) to watch the deployment we created in step 1.
```
cd cpu/v2beta2_YamlApi/scenario2_cpu_metric_value/
oc apply -f HorizontalPodAutoscaler.yaml -n <The namespace name that you will be creating the deployment and hpa in.>
```


3. After waiting a few minutes (so the hpa can begin to accurately get metrics from the initial pod),
Open the terminal of the pod that was deployed in step 1. and stress test the cpu for about 5 minutes. As most of the pods that are
being booted up take time to be ready so they may not be used in subsequent desiredReplicas calculations. 
```
stress --cpu 1 --timeout 5m -v
```

OR Optionally if you want the dates/times recorded in the pod terminal.
```
date "${DATE_FORMAT}"  &&  \
stress --cpu 1 --timeout 5m -v	&& \
date "${DATE_FORMAT}" 
```


4. Use the web console OR the following two commands to watch the current pods over time along with a description
of the horizontalpodautoscalers and the events that are happening to it. 

Terminal Window 1>
```
watch oc adm top pods -n <The namespace name that you created the deployment and hpa.>

# Output looks something like
NAME                                 CPU(cores)   MEMORY(bytes)
openshift-toolbox-6dcd785db8-67rdr   0m           6Mi

```

Terminal Window 2>
```
watch oc describe hpa openshift-toolbox-hpa -n <The namespace name that you created the deployment and hpa.>

# Output looks something like
Name:                    openshift-toolbox-hpa
Namespace:               rhn-gps-fharo-dev
Reference:               Deployment/openshift-toolbox
Metrics:                 ( current / target )
  resource cpu on pods:  0 / 250m
Deployment pods:         1 current / 1 desired
Conditions:
  Type            Status  Reason            Message
  ----            ------  ------            -------
  AbleToScale     True    ReadyForNewScale  recommended size matches current size
  ScalingActive   True    ValidMetricFound  the HPA was able to successfully calculate a replica count from cpu resource
  ScalingLimited  True    TooFewReplicas    the desired replica count is less than the minimum replica count
Events:
  Type     Reason                        Age                 From                       Message
  ----     ------                        ----                ----                       -------
  Warning  FailedComputeMetricsReplicas  38m (x12 over 41m)  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu utilization: did not receive metrics for any ready pods
  Warning  FailedGetResourceMetric	 38m (x13 over 41m)  horizontal-pod-autoscaler  failed to get cpu utilization: did not receive metrics for any ready pods
  Normal   SuccessfulRescale             35m                 horizontal-pod-autoscaler  New size: 2; reason: cpu resource above target
  Normal   SuccessfulRescale             25m                 horizontal-pod-autoscaler  New size: 1; reason: All metrics below target
...

```



## Demo 2 - Memory Utilization Average Value:

This section is about deploying a HorizontalPodAutoscaler that watches 5Mi of average memory utilization across pods in a Deployment and scales up/down with specified behavior.

1. Create the deployment. 
 
Note You may want to change the TZ environment variable to your timezone in the deployment yaml, so we print out timestamps they are relative to your time.
```
oc apply -f DeploymentUsingQuayIoImage.yaml -n <The namespace name that you will be creating the deployment and hpa in.>
```


2. Create the horizontalpodautoscaler (hpa) to watch the deployment we created in step 1.
```
cd memory/v2beta2_YamlApi/scenario1_metric_memory_via_avg_value_across_pods/
oc apply -f HorizontalPodAutoscaler.yaml -n <The namespace name that you will be creating the deployment and hpa in.>
```


3. After waiting a few minutes (so the hpa can begin to accurately get metrics from the initial pod), open the terminal of the pod that was deployed in step 1. and stress test the memory for about 3 minutes by writing a 512 MB temporary file to disk. 

Note: As most of the pods that are being booted up take time to be ready they may not be used in subsequent desiredReplicas calculations. 
```
stress -d 1 --hdd-bytes 512MB --timeout 3m
```

OR Optionally if you want the dates/times recorded in the pod terminal.
```
date "${DATE_FORMAT}" && \
stress -d 1 --hdd-bytes 512MB --timeout 3m && \
date "${DATE_FORMAT}"
```


1. Use the web console OR the following two commands to watch the current pods over time along with a description of the horizontalpodautoscalers and the events that are happening to it. 

Terminal Window 1>
```
watch oc adm top pods -n <The namespace name that you created the deployment and hpa.>

# Output looks something like
NAME                                 CPU(cores)   MEMORY(bytes)
openshift-toolbox-5bdbb9948-kmdfp    0m           8Mi

```

Terminal Window 2>
```
watch oc describe hpa openshift-toolbox-hpa -n <The namespace name that you created the deployment and hpa.>

# Output looks something like
Name:                       openshift-toolbox-hpa
Namespace:                  rhn-gps-fharo-dev
Labels:                     <none>
Annotations:                <none>
CreationTimestamp:          Sat, 07 Aug 2021 18:30:53 -0700
Reference:                  Deployment/openshift-toolbox
Metrics:                    ( current / target )
  resource memory on pods:  9547190857m / 5Mi
Min replicas:               1
Max replicas:               9
Behavior:
  Scale Up:
    Stabilization Window: 0 seconds
    Select Policy: Max
    Policies:
      - Type: Pods     Value: 2    Period: 60 seconds
      - Type: Percent  Value: 100  Period: 60 seconds
  Scale Down:
    Stabilization Window: 300 seconds
    Select Policy: Max
    Policies:
      - Type: Pods  Value: 2  Period: 60 seconds
Deployment pods:    9 current / 9 desired
Conditions:
  Type            Status  Reason            Message
  ----            ------  ------            -------
  AbleToScale     True    ReadyForNewScale  recommended size matches current size
  ScalingActive   True    ValidMetricFound  the HPA was able to successfully calculate a replica count from memory resource
  ScalingLimited  True    TooManyReplicas   the desired replica count is more than the maximum replica count
Events:
  Type     Reason                        Age    From                       Message
  ----     ------                        ----   ----                       -------
  Warning  FailedGetResourceMetric       9m57s  horizontal-pod-autoscaler  failed to get memory utilization: unable to get metrics for resource memory: no metrics returned from resource metrics API
  Warning  FailedComputeMetricsReplicas  9m57s  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get memory utilization: unable to get metrics for resource memory: no metrics returned from resource metrics API
  Normal   SuccessfulRescale             9m42s  horizontal-pod-autoscaler  New size: 2; reason: memory resource above target
  Normal   SuccessfulRescale             3m11s  horizontal-pod-autoscaler  New size: 3; reason: memory resource above target
  Normal   SuccessfulRescale             2m11s  horizontal-pod-autoscaler  New size: 4; reason: memory resource above target
  Normal   SuccessfulRescale             101s   horizontal-pod-autoscaler  New size: 5; reason: memory resource above target
  Normal   SuccessfulRescale             86s    horizontal-pod-autoscaler  New size: 6; reason: memory resource above target
  Normal   SuccessfulRescale             71s    horizontal-pod-autoscaler  New size: 8; reason: memory resource above target
  Normal   SuccessfulRescale             41s    horizontal-pod-autoscaler  New size: 9; reason: memory resource above target
...

```




References:

https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

https://docs.openshift.com/container-platform/4.7/nodes/pods/nodes-pods-autoscaling.html#nodes-pods-autoscaling-creating-cpu_nodes-pods-autoscaling

https://docs.openshift.com/container-platform/4.7/nodes/pods/nodes-pods-viewing.html

https://docs.openshift.com/enterprise/3.1/dev_guide/compute_resources.html