---
author: "Marcel Widmer"
date : "2022-09-24"
title: Axon Framework - MongoDB extension
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



# Commands
* A command tells our application to do something

# Events
* An event is a notification of something that _has_ happened.

# Query
* Queries could be _simplified_ by storing a copy of the data in a form easily
* In many cases, updating the query models can happen asynchronously from processing the transaction: _eventual consistency_


# Create Project
Run the following commands :
```bash
export KBOOT_NAME=kboot-camel
export KBOOT_APPL_NAME=KbootCamel

http https://start.spring.io/starter.tgz \
    dependencies==camel,actuator,webflux \
    description=="Demo project Spring Boot" \
    applicationName==$KBOOT_APPL_NAME \
    name==$KBOOT_NAME \
    groupId==ch.keepcalm \
    artifactId==$KBOOT_NAME \
    packageName==ch.keepcalm.demo \
    javaVersion==11 \
    language==kotlin \
    baseDir==$KBOOT_NAME| tar -xzvf -


cd $KBOOT_NAME

http https://raw.githubusercontent.com/marzelwidmer/marzelwidmer.github.io/master/img/banner.txt \
    > src/main/resources/banner.txt

rm src/main/resources/application.properties

echo "spring:
  application:
    name: $KBOOT_NAME" | > src/main/resources/application.yaml

idea .
```
