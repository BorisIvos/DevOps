#!/bin/bash

# Fetch Minikube IP
MINIKUBE_IP=$(minikube ip)

# Get the NodePort values for Redis master and replica
REDIS_MASTER_NODE_PORT=$(kubectl get svc redis-master -n redis -o jsonpath='{.spec.ports[?(@.name=="client")].nodePort}')
REDIS_REPLICA_NODE_PORT=$(kubectl get svc redis-replica -n redis -o jsonpath='{.spec.ports[?(@.name=="client")].nodePort}')

# Export environment variables
export REDIS_MASTER_HOST_PORT="${MINIKUBE_IP}:${REDIS_MASTER_NODE_PORT}"
export REDIS_SLAVE_HOST_PORT="${MINIKUBE_IP}:${REDIS_REPLICA_NODE_PORT}"

# Print the exported variables
echo "REDIS_MASTER_HOST_PORT=${REDIS_MASTER_HOST_PORT}"
echo "REDIS_SLAVE_HOST_PORT=${REDIS_SLAVE_HOST_PORT}"
