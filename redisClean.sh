#!/bin/bash

# Set variables
NAMESPACE="redis"
REDIS_MASTER_DEPLOY="redis-master"
REDIS_MASTER_POD=$(kubectl -n $NAMESPACE get pods -l app=$REDIS_MASTER_DEPLOY -o jsonpath='{.items[0].metadata.name}')
REDIS_PASSWORD="Securep@55Here"

# Flush all data in Redis
echo "Flushing all data from Redis..."
kubectl -n $NAMESPACE exec -it $REDIS_MASTER_POD -- /usr/local/bin/redis-cli -a $REDIS_PASSWORD FLUSHALL

echo "All data has been deleted from Redis."
