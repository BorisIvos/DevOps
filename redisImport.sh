#!/bin/bash

# Set variables
NAMESPACE="redis"
DATA_FILE="data.txt"
REDIS_MASTER_DEPLOY="redis-master"
REDIS_MASTER_POD=$(kubectl -n $NAMESPACE get pods -l app=$REDIS_MASTER_DEPLOY -o jsonpath='{.items[0].metadata.name}')
REDIS_PASSWORD="Securep@55Here"

# Import data from data.txt into Redis
echo "Importing data from $DATA_FILE into Redis..."
cat $DATA_FILE | kubectl -n $NAMESPACE exec -i $REDIS_MASTER_POD -- /usr/local/bin/redis-cli -a $REDIS_PASSWORD

# Check keys in Redis master
echo "Checking keys in Redis master..."
KEYS_OUTPUT=$(kubectl -n $NAMESPACE exec -it $REDIS_MASTER_POD -- /usr/local/bin/redis-cli -a $REDIS_PASSWORD KEYS "*")

# Verify if keys exist
if [ -z "$KEYS_OUTPUT" ]; then
    echo "No keys found in Redis."
else
    echo "Keys in Redis master:"
    echo "$KEYS_OUTPUT"
    echo "Data imported successfully."
fi

echo "Done."

