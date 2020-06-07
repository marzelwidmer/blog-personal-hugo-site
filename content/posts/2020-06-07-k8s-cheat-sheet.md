---
title: Kubernetes cheat sheet
subTitle: K8s cheat sheet tips and tricks
date: "2020-06-07"
draft: false
tags: [K8s]
categories: [Kubernetes]
---



# Config Maps
Create `ConfigMap` from file is also a useful way to create a `ConfigMap`
```bash
$ oc create configmap order-service --from-file=src/main/resources/application.yaml
```

Get all `ConfigMaps`
```bash
$ oc get configmaps
```

Get `ConfigMap` as `yaml`
```bash
$ oc get configmap order-service -o yaml
```

Describe `ConfigMap`
```bash
$ oc describe configmap order-service
```

Delete `ConfigMap`
```bash
$ oc delete configmap order-service
```
