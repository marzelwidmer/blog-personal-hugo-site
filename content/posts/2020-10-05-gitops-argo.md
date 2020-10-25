---
title: GitOps with Argo CD
subTitle: Set up Argo CD on Minikube 
date: "2020-10-25"
draft: false
tags: [K8s]
categories: [Kubernetes]
--- 
[Argo CD](https://argoproj.github.io/argo-cd/) is a declarative, GitOps continuous delivery tool for Kubernetes.
Application definitions, configurations, and environments should be declarative and version controlled. 
Application deployment and lifecycle management should be automated, auditable, and easy to understand.

* [Minikube Setup]({{<ref "#minikube" >}}) 
* [Install Argo CD]({{<ref "#argoCD" >}}) 
* [Create App on Argo CD]({{<ref "#argoCreatApp" >}})

# Minikube Setup {#minikube}   
Local Development Environment with minikube.

## Brew Installation Packages
```
brew install hyperkit
brew install minikube
brew install httpie
brew install stern
brew install argocd
brew install sops
```

## OSX Minikube Test Cluster
### Hyperkit
Setup first minikube hyperkit driver.
```
minikube config set driver hyperkit
```

### Minikube Addons
Configure some addons for the test cluster.
```
minikube addons enable dashboard -p test
minikube addons enable metrics-server -p test
minikube addons enable ingress -p test
minikube addons enable registry -p test
```
### Start Minikube 
Now start the minikube test cluster with some memory and cpu settings.
```
minikube start --memory 6144 --cpus 4 -p test
```



# Install ARGO CD {#argoCD} 
Create a separate namespace `argocd` to install argo.
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
## Port Forwarding to ARGO Server
```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Change Argo Admin Password
The default Password is the Argo Server name.
```
kubectl get pod -n argocd | grep argocd-server
argocd-server-5bc896856-xvt92                    1/1     Running   0          71m
```
Use the Argo CLI to login with user `admin` and change the password.
```
argocd login localhost:8080
argocd account update-password
```

![Argo](/gitops-argo/argo.png)


# Create App with directory-recurse {#argoCreatApp} 
```
argocd app create kboot --repo https://github.com/marzelwidmer/argo-demo.git \
    --path manifest \
    --directory-recurse \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace default
```
## Synch App
Argo will be sync every 5 min. You can force it via AdminUI `https://localhost:8080` or  with the following command :
```
argocd app sync kboot
```



## Test Contracts inside K8s
```
kubectl run -i --rm --restart=Never curl-client \
    --image=tutum/curl:alpine \
    --command -- curl -s 'http://contracts/api/persons' -H 'Content-Type: application/json' -w "\n"

[{"firstName":"John"}]
pod "curl-client" deleted
```

## Test Contracts over Ingress
You can edit the `/etc/hosts` file for details please check my other Blog [Minikube Ingress Controller](https://blog.marcelwidmer.org/posts/2020-05-01-minikube-ingress-controller) 
```
http -j http://test.minikube.me/api/persons

HTTP/1.1 200 OK
Connection: keep-alive
Content-Encoding: gzip
Content-Type: application/json
Date: Sun, 25 Oct 2020 08:34:33 GMT
Matched-Stub-Id: e6546194-eda5-4d86-b644-9694fd421ed6
Server: nginx/1.19.1
Transfer-Encoding: chunked
Vary: Accept-Encoding, User-Agent

[
    {
        "firstName": "John"
    }
]

```



# Comming soon...
Manage Secrets with `SealedSecrets`

## Sealed Secrets
Install Sealed Secrets with Helm to manage Secrets. 
see: https://hub.kubeapps.com/charts/stable/sealed-secrets
```
helm install sealed --namespace kube-system stable/sealed-secrets
```
### Install client-side tool into /usr/local/bin/
```
GOOS=$(go env GOOS)
GOARCH=$(go env GOARCH)
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.12.4/kubeseal-$GOOS-$GOARCH
sudo install -m 755 kubeseal-$GOOS-$GOARCH /usr/local/bin/kubeseal
```
### Create a sealed secret file for Redis
```
kubectl create secret generic redis --dry-run=client --from-literal=database-password=verySecurePassword -o yaml | \
 kubeseal \
 --controller-name=sealed-sealed-secrets \
 --controller-namespace=kube-system \
 --format yaml > sealed-redis-secret.yaml
```
### Apply the sealed secret
```
kubectl create -f sealed-redis-secret.yaml
```
### Get Secret
Running `kubectl get secret redis -o yaml` will show the decrypted secret that was generated from the sealed secret.
Both the SealedSecret and generated Secret must have the same name and namespace.
```
kubectl get secret redis -o yaml
```
See:
https://github.com/bitnami-labs/sealed-secrets




_References:_
> [Blog Minikube Ingress Controller](https://blog.marcelwidmer.org/posts/2020-05-01-minikube-ingress-controller/)
> [ingress-minikube](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
