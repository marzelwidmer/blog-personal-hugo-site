---
author: "Marcel Widmer"
date : "2022-09-24"
title: Axon Framework with MongoDB extension and Onion Architecture
description: "AxonIQ - Spring Boot - MongoDB extension - CQRS"
tags: [Spring Boot, Axon, CQRS]
categories: [Development]
ShowToc: true
TocOpen: true
---

![axon-cqrs](/static/axon/axon-cqrs.jpg)

In this blog post we look into [Axon Framework](https://www.axoniq.io) is a framework for building evolutionary, event-driven microservice systems, based on the principles of Domain Driven Design, Command-Query Responsibility Segregation (CQRS) and Event Sourcing.

We will disable the Axon Server and replaced it with the [MongoDB extension](https://github.com/AxonFramework/extension-mongo) this extension provides functionality to leverage Mongo as an EventStorageEngine (to be used by an EventStore) and TokenStore.

For more information on anything Axon, please visit our website, [Axon Framework](https://www.axoniq.io).

# Commands / Events Query 
- A command tells our application to do something
- An event is a notification of something that _has_ happened.
- Queries could be _simplified_ by storing a copy of the data in a form easily In many cases, updating the query models can happen asynchronously from processing the transaction: _eventual consistency_

# Project Setup

Let's create a Maven Spring Boot project with the following dependencies from [start.spring.io](https://start.spring.io)
- actuator
- webflux
- hateoas
- reactive mongodb

Run the following commands :
```shell
export KBOOT_NAME=kboot-axon
export KBOOT_APPL_NAME=KbootAxonDemoApplication
export KBOOT_APPL_DESC="Axon Demo Project"
export KBOOT_JAVA_VERS=17
export KBOOT_PACKAGE_NAME="ch.keepcalm.demo"

http https://start.spring.io/starter.tgz \
    dependencies==actuator,webflux,data-mongodb-reactive,hateoas \
    description==$KBOOT_APPL_DESC \
    applicationName==$KBOOT_APPL_NAME \
    name==$KBOOT_NAME \
    groupId==ch.keepcalm \
    artifactId==$KBOOT_NAME \
    packageName==$KBOOT_PACKAGE_NAME \
    javaVersion==$KBOOT_JAVA_VERS \
    language==kotlin \
    baseDir==$KBOOT_NAME| tar -xzvf -
``` 

Change in de folder :
- add `banner.txt` 
- replace `application.properties` with `application.yaml` configuration file.

```shell
cd $KBOOT_NAME

http https://raw.githubusercontent.com/marzelwidmer/marzelwidmer.github.io/master/img/banner.txt \
    > src/main/resources/banner.txt

rm src/main/resources/application.properties

echo "spring:
  application:
    name: $KBOOT_NAME" | > src/main/resources/application.yaml
```

## Onion Architecture 

![ports-and-adapters](/static/axon/ports-and-adapter.png)


folder structure 

```shell
.
├── application  (1)
├── domain  (2)
└── infrastructure  (3)
    ├── api
    ├── client
    ├── configuration
    ├── exception
    ├── logging
    ├── mongo
    └── persistence
```
    
1. Application services responsible for providing access to the domain to external clients. An application service orchestrates use cases, but does not contain business logic.

2. Core Domain Model, Entity, ValueObject (DDD) 

3. Infrastructure services. An infrastructure service provides functionality to the domain that requires additional infrastructure only available outside the domain. The infrastructure service interface forms part of the domain, the implementation is part of the infrastructure.


```shell
mkdir -p src/main/kotlin/${KBOOT_PACKAGE_NAME//.///}/{infrastructure/{persistence,logging,exception,configuration,client,mongo,api},application,domain}
```

```shell
.
└── src
    ├── main
    │   ├── kotlin
    │   │   └── ch
    │   │       └── keepcalm
    │   │           └── demo
    │   │               ├── application
    │   │               ├── domain
    │   │               └── infrastructure
    │   │                   ├── api
    │   │                   ├── client
    │   │                   ├── configuration
    │   │                   ├── exception
    │   │                   ├── logging
    │   │                   ├── mongo
    │   │                   └── persistence
    │   └── resources
    └── test
        └── kotlin
            └── ch
                └── keepcalm
                    └── demo
```

Let's modify the _pom.xml_ to handle `HATEOAS` with `WebFlux`.
Search the `spring-boot-starter-hateoas` dependency and exclude the `spring-boot-starter-web`
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-hateoas</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```


