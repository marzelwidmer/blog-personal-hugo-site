---
title: Kubernetes Hazelcast Distributed Caching  
subTitle: Spring Boot with Embedded Hazelcast Distributed Caching on Openshift  
date: "2020-10-04"
draft: false
tags: [K8s, SpringBoot, Caching]
categories: [Kubernetes]
---
The sample code can be found on GitHub. [^GitHub] 

* [Precondition Spring Caching with Hazelcast]({{<ref "#precondition" >}}) 
* [Kustomize Configuration]({{<ref "#kustomize" >}}) 
* [Hazelcast Configuration]({{<ref "#hazelcastConfiguration" >}}) 


### Precondition Spring Caching with Hazelcast {#precondition}
Let's get ready first our Spring Boot application with the following dependencies.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
``` 
And also let's take the `hazelcast-all` from `com.hazelcast` that include the `k8s` dependencies.
The version `4.x.x`  will also support `yaml` configuration of hazelcast.
```xml
<dependency>
    <groupId>com.hazelcast</groupId>
    <artifactId>hazelcast-all</artifactId>
    <version>4.0.3</version>
</dependency>
```

Let's implement a real `foo` service with a super `Jack Norris` API for the moment.
The API will take a string on `/api/[key]` eg. `/api/foo` this will create a `UUID` and will put it in the cache and give it back as response.
The second call with the same key `foo` will gibve the same `UUID` if a cache hit.  

1. Let's enable the caching 
   ```@EnableCaching```
2. Implement the Rest API with the `@CacheConfig` annotation.

```kotlin
@SpringBootApplication
@EnableCaching
class DemoHazelcastApplication

fun main(args: Array<String>) {
	runApplication<DemoHazelcastApplication>(*args)
}

@RestController
@RequestMapping(value = ["/api"], produces = [MediaType.APPLICATION_JSON_VALUE])
class Controller(private val cache: Cache) {

	@GetMapping(path = ["/{key}"])
	fun getStuff(@PathVariable("key") key: String) = cache.getUUID(key)
}

@CacheConfig(cacheNames = ["map"])
@Service
class Cache {
	@Cacheable(value = ["map"], key = "#key")
	fun getUUID(key: String): UUID? = UUID.randomUUID().also { println("Generated $it") }
}
```

### Kustomize Configuration {#kustomize}
For the `kustomize` configuration I will only point to the important hazelcast configurations. 
You can find the configurations on GitHub. [^GitHub]  
#### Deployment
The important point in the `Deployment` ist to expose the `containerPort: 5701` for the Hazelcast communications (synchronization) between the Pods.
```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - image: c3smonkey/template
          name: hazelcast-demo
          ports:
            - containerPort: 8080
              name: 8080-tcp
              protocol: TCP
            - containerPort: 5701
              name: 5701-tcp
              protocol: TCP
```

### Hazelcast Configuration {#hazelcastConfiguration}
The important part here is the `hazelcast.network.join.kubernetes.service-dns` who point to the internal service address.
```yaml
hazelcast:
  network:
    join:
      multicast:
        enabled: false
      kubernetes:
        enabled: true
        namespace: dev
        service-dns: hazelcast-demoservice.dev.svc.cluster.local
```



[^GitHub]: [hazelcast-demo](https://github.com/marzelwidmer/hazelcast-demo)

