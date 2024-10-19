#!/bin/bash

set -e

NAMESPACE="redis"

# Check if namespace exists, if not, create it
if ! kubectl get namespace $NAMESPACE; then
  kubectl create namespace $NAMESPACE
fi

# Apply Secret
kubectl apply -f redis-secret.yaml

# Apply ConfigMap for Redis master
kubectl apply -f redis-master-config.yaml

# Apply PersistentVolume for Redis master
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis-master-pv
  namespace: $NAMESPACE
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data/redis-master
EOF

# Apply PersistentVolumeClaim for Redis master
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-master-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Apply Deployment for Redis master with node affinity to master node
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-master
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-master
  template:
    metadata:
      labels:
        app: redis-master
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - minikube  # Ensure master runs on the master node
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
          name: client
        - containerPort: 16379
          name: gossip
        command: ["redis-server", "/conf/redis.conf"]
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: redis-password
        volumeMounts:
        - name: conf
          mountPath: /conf
          readOnly: false
        - name: redis-storage
          mountPath: /data
      volumes:
      - name: conf
        configMap:
          name: redis-master-config
          defaultMode: 0755
      - name: redis-storage
        persistentVolumeClaim:
          claimName: redis-master-pvc
EOF

# Apply Service for Redis master with NodePort
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: redis-master
  namespace: $NAMESPACE
spec:
  type: NodePort
  ports:
  - port: 6379
    targetPort: 6379
    nodePort: 30079
    name: client
  - port: 16379
    targetPort: 16379
    nodePort: 31679
    name: gossip
  selector:
    app: redis-master
EOF

# Wait for Redis master to be ready
echo "Waiting for Redis master to be ready..."
kubectl wait --namespace $NAMESPACE --for=condition=ready pod --selector=app=redis-master --timeout=120s

# Apply ConfigMap for Redis replica
kubectl apply -f redis-replica-config.yaml

# Apply Deployment for Redis replica with node affinity to the second node
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-replica
  namespace: $NAMESPACE
spec:
  replicas: 1  # Change to 1 replica
  selector:
    matchLabels:
      app: redis-replica
  template:
    metadata:
      labels:
        app: redis-replica
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - minikube-m02  # Ensure replica runs on minikube-m02
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 7000
          name: client
        - containerPort: 17000
          name: gossip
        command: ["redis-server", "/conf/redis.conf"]
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: redis-password
        volumeMounts:
        - name: conf
          mountPath: /conf
          readOnly: false
      volumes:
      - name: conf
        configMap:
          name: redis-replica-config
          defaultMode: 0755
EOF

# Apply Service for Redis replica with NodePort
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: redis-replica
  namespace: $NAMESPACE
spec:
  type: NodePort
  ports:
  - port: 7000
    targetPort: 7000
    nodePort: 32402  # Updated nodePort
    name: client
  - port: 17000
    targetPort: 17000
    nodePort: 31701  # Updated nodePort
    name: gossip
  selector:
    app: redis-replica
EOF

# Wait for Redis replica to be ready
echo "Waiting for Redis replica to be ready..."
kubectl wait --namespace $NAMESPACE --for=condition=ready pod --selector=app=redis-replica --timeout=120s

echo "Redis master and replica have been successfully deployed."
