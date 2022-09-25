---
title: Axon Framework - MongoDB extension
subTitle: AxonIQ - Spring Boot - MongoDB extension - CQRS  
date: "2022-09-24"
draft: false
tags: [axon, cqrs]
categories: [Development]
---

![axon-cqrs](/static/axon/axon-cqrs.jpg)
![bbc](/static/axon/bbc.jpg)



Commands:
* A command tells our application to do something

Events:
* An event is a notification of something that _has_ happened.

Query:
* Queries could be _simplified_ by storing a copy of the data in a form easily
* In many cases, updating the query models can happen asynchronously from processing the transaction: _eventual consistency_


Projection :
* Optimized for the specific read use-cases (e.g. screens, API methods)
* Many separated ones instead of one big one
* Use carious technologies as appropriate (RDMS, Elastic, Mongo etc.)
