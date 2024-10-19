#!/bin/bash

set -e

NAMESPACE="redis"

# Check if namespace exists, if not, create it
if ! kubectl get namespace $NAMESPACE; then
  kubectl create namespace $NAMESPACE
fi

# Apply ConfigMap for CronJob script
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-info-script
  namespace: $NAMESPACE
data:
  redis-info.sh: |
    #!/bin/bash
    REDIS_MASTER_POD=\$(kubectl -n $NAMESPACE get pods -l app=redis-master -o jsonpath='{.items[0].metadata.name}')
    kubectl -n $NAMESPACE exec -it \$REDIS_MASTER_POD -- /usr/local/bin/redis-cli -a Securep@55Here INFO replication
EOF

# Apply ServiceAccount for CronJob
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: redis-cronjob-sa
  namespace: $NAMESPACE
EOF

# Apply Role for CronJob
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: $NAMESPACE
  name: redis-cronjob-role
rules:
- apiGroups: [""]
  resources: ["pods", "pods/exec"]
  verbs: ["get", "list", "create", "exec"]
EOF

# Apply RoleBinding for CronJob
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: redis-cronjob-rolebinding
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: redis-cronjob-sa
  namespace: $NAMESPACE
roleRef:
  kind: Role
  name: redis-cronjob-role
  apiGroup: rbac.authorization.k8s.io
EOF

# Apply CronJob for executing Redis INFO replication every minute
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: redis-info-cronjob
  namespace: $NAMESPACE
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: redis-cronjob-sa
          initContainers:
          - name: copy-script
            image: busybox
            command: ['sh', '-c', 'cp /tmp/redis-info.sh /script/redis-info.sh && chmod +x /script/redis-info.sh']
            volumeMounts:
            - name: script
              mountPath: /tmp
            - name: script-copy
              mountPath: /script
          containers:
          - name: redis-info
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              /script/redis-info.sh
            volumeMounts:
            - name: script-copy
              mountPath: /script
          restartPolicy: OnFailure
          volumes:
          - name: script
            configMap:
              name: redis-info-script
          - name: script-copy
            emptyDir: {}
EOF

echo "CronJob for Redis INFO replication has been successfully created."

