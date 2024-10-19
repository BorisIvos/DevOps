#!/bin/bash

NAMESPACE="redis"

# Delete the CronJob
kubectl delete cronjob redis-info-cronjob -n $NAMESPACE

# Delete the RoleBinding
kubectl delete rolebinding redis-cronjob-rolebinding -n $NAMESPACE

# Delete the Role
kubectl delete role redis-cronjob-role -n $NAMESPACE

# Delete the ServiceAccount
kubectl delete serviceaccount redis-cronjob-sa -n $NAMESPACE

# Delete the ConfigMap
kubectl delete configmap redis-info-script -n $NAMESPACE



echo "All resources for the Redis CronJob have been successfully deleted."
