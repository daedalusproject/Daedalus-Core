# Kubernetes

This project is deployed over Windmaker's Kubernetes cluster.

## Prerequisites

As cluster admin you should create namespaces and specific service account to operate over those namespaces.

```bash
kubectl apply -f setup.yaml
```

Gitlab CI/CD needs gitlab-daedalus-core-deployer:
```
kubectl -n daedalus-core-testing describe secrets $(kubectl -n daedalus-core-testing get secret | grep gitlab-daedalus-core-deployer | awk  '{print $1}') | grep token: | awk  '{print $2}'
kubectl -n daedalus-core-develop describe secrets $(kubectl -n daedalus-core-develop get secret | grep gitlab-daedalus-core-deployer | awk  '{print $1}') | grep token: | awk  '{print $2}'
```

Three namespaces will be created:

* daedalus-core-testing
* daedalus-core-develop
* daedalus-core-staging
* daedalus-core

### Install Gitlab runner

Download Helm 3
```bash
cd $(mktemp -d)
wget https://get.helm.sh/helm-v3.0.0-linux-amd64.tar.gz
tar -zxvf helm-v3.0.0-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
```

Add gitlab chart
```bash
/usr/local/bin/helm  repo add gitlab https://charts.gitlab.io
```

Create values.yml:
````yml
imagePullPolicy: IfNotPresent

gitlabUrl: https://git.daedalus-project.io/

runnerRegistrationToken: "toke-provided-by-gitlab"

unregisterRunners: true

concurrent: 1

checkInterval: 30

rbac:
  create: true

  clusterWideAccess: true

metrics:
  enabled: true

runners:
  image: ubuntu:bionic
  tags: "kubernetes"
  privileged: true
  cache: {}
  builds: {}
  services: {}
  helpers: {}

resources: {}
affinity: {}
nodeSelector: {}
tolerations: []
hostAliases: []
podAnnotations: {}
````

Deploy Gitlab Runner
```bash
/usr/local/bin/helm install gitlab-daedalus-core-deployer  --namespace daedalus-core -f values.yaml gitlab/gitlab-runner
```

Create tls secret:
```bash
kubectl create secret tls daedalus-core-develop-cert --key daedalus-project.io.key --cert daedalus-project.io.pem -n daedalus-core-develop
```

