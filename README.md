# Presto DB

## Required tools

- docker
- htpasswd
- kubectl
- kubernetes cluster

## Docker image

| Images            | Tags   |
| ----------------- | ------ |
| lumenore/prestodb | latest |
| lumenore/prestodb | 0.281  |

## Build your own image

```bash
PRESTO_VERSION=0.281
DOCKER_REPO="lumenore/prestodb"

docker build --build-arg PRESTO_VERSION=${PRESTO_VERSION} . -t ${DOCKER_REPO}:${PRESTO_VERSION}
docker push ${DOCKER_REPO}:${PRESTO_VERSION}
```

## Generate password

Password files utilizing the bcrypt format can be created using the htpasswd utility from the Apache HTTP Server. The cost must be specified, as Presto enforces a higher minimum cost than the default.

```bash
USERNAME="admin"
touch password.db
htpasswd -B -C 10 password.db ${USERNAME}
```

## Create secret for passwords

Presto can be configured to enable frontend password authentication over HTTPS for clients, such as the CLI, or the JDBC and ODBC drivers. The username and password are validated against usernames and passwords stored in a file.

```bash
kubectl create secret generic presto-db-authentication-db --from-file=password.db
```

## Create access-control

A system access control plugin enforces authorization at a global level, before any connector level authorization.
You can find reference [here](https://prestodb.io/docs/current/security/built-in-system-access-control.html)

```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: presto-db-access-control
data:
  rules.json: |
    {
      "catalogs": [
        {
          "allow": true
        }
      ]
    }
EOF
```

## Storage Persistance

| Kind       | Location         |
| ---------- | ---------------- |
| Data Store | /var/presto/data |

## Deploy

```bash
IMAGE="lumenore/prestodb:0.281"
HOST_PATH="<PATH OF YOUR etc folder>"  #Change your Hostpath or attach storage and copy etc folder

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: presto-db
  labels:
    app.kubernetes.io/name: presto-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: presto-db
  template:
    metadata:
      labels:
        app.kubernetes.io/name: presto-db
    spec:
      hostname: presto-db
      volumes:
        - name: presto-db-access-control
          configMap:
            name: presto-db-access-control
        - name: presto-db-authentication-db
          secret:
            secretName: presto-db-authentication-db
        - name: etc-storage
          hostPath:
            path: ${HOST_PATH}
            type: DirectoryOrCreate
      containers:
        - name: presto-db
          image: ${IMAGE}
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - name: presto-db-access-control
              mountPath: /tmp/access/
              readOnly: true
            - name: presto-db-authentication-db
              mountPath: /tmp/auth/
              readOnly: true
            - name: etc-storage
              mountPath: /opt/presto/etc
              readOnly: true
---
apiVersion: v1
kind: Service
metadata:
  name: presto-db
spec:
  selector:
    app.kubernetes.io/name: presto-db
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
EOF
```

## Connect

You can connect with presto-cli withing cluster over port 8080.

```bash
presto --server https://presto-db:8080 --user <USERNAME>  --password
```
