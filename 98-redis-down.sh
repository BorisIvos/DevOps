#!/bin/bash

set -e

NAMESPACE="redis"

# Delete services
kubectl delete service redis-replica -n $NAMESPACE || echo "Service redis-replica not found."
kubectl delete service redis-master -n $NAMESPACE || echo "Service redis-master not found."

# Delete deployments
kubectl delete deployment redis-replica -n $NAMESPACE || echo "Deployment redis-replica not found."
kubectl delete deployment redis-master -n $NAMESPACE || echo "Deployment redis-master not found."

# Delete PersistentVolumeClaim
kubectl delete persistentvolumeclaim redis-master-pvc -n $NAMESPACE || echo "PersistentVolumeClaim redis-master-pvc not found."

# Delete PersistentVolume (if not in use)
kubectl delete persistentvolume redis-master-pv || echo "PersistentVolume redis-master-pv not found."

# Delete ConfigMaps
kubectl delete configmap redis-replica -n $NAMESPACE || echo "ConfigMap redis-replica not found."
kubectl delete configmap redis-master -n $NAMESPACE || echo "ConfigMap redis-master not found."

# Delete namespace
kubectl delete namespace $NAMESPACE || echo "Namespace $NAMESPACE not found."

echo "All Redis resources have been deleted."

