---
title: Kboot Flux Meets Soap
subTitle: Leading edge meets legacy
date: "2020-05-10"
draft: false
tags: [SpringBoot, Kotlin, WebFlux]
---

This will demonstrate how we can deal with a `Blocking API` in a `Reactive World`.

The GitHb [^GitHub] sample provides a 
* `soap-server` who demonstrate the blocking downstream `API`.
* `flux-client` with `REST API` 
  * `lockdown` that will call the blocking `SOAP` endpoint and. Blockhound [^Blockhound] will throw an exception.
  * `easing` have an implemented from Avoiding Reactor Meltdown [^AvoidingReactorMeltdown] show case how to manage `Blocking API`.

With this approach to manage `Blocking API` in the same service ant not in a separate service we have all the nice features like `retry` `filter` `map` and so on
in our `Service A` from the `Reactive Streams API`. 

We also not have to manage a other service who will handle it for us. With this we have less network hops, Organisations-Issues, Deployment etc. who are sometimes increase complexity and so on.

* [Rest API]({{<ref "#restAPI" >}}) 
* [BlockHound Plugin]({{<ref "#blockHound" >}})       
* [SOAP Server]({{<ref "#soapServer" >}})     
* [SOAP with HTTPie Server]({{<ref "#httpieSoapCall" >}}) 
* [Implementation]({{<ref "#implementation" >}})    


![fluxMeetsSoap](/2020-05-10-kboot-flux-meets-soap/FluxMeetsSoap.png)


# Flux Client  {#restAPI} 
## API Lockdown Switzerland
```bash
http :8080/api/lockdown/Switzerland
```


## API easing Switzerland
```bash
http :8080/api/easing/Switzerland
```



## Blockhound  {#blockHound}  
[BlockHound](https://github.com/reactor/BlockHound) is a Java agent to detect blocking calls from non-blocking threads. 
Add the following or latest dependency from `blockhound`.
```xml
<!-- Blockhound	-->
<dependency>
    <groupId>io.projectreactor.tools</groupId>
    <artifactId>blockhound</artifactId>
    <version>1.0.3.RELEASE</version>
</dependency>
```

Install the agent `BlockHound.install()`
```kotlin
fun main(args: Array<String>) {
	BlockHound.install()
	runApplication<KbootFluxWS>(*args)
}
```
 
# SOAP Server  {#soapServer} 
The Server have an implementation with a demonstration how we can write own `Kotlin DSL`.

## DSL [^KotlinDSLinUnderAnhour]
```kotlin
 country {
    name = "Switzerland"
    capital = "Bern"
    population = 8_603_900
    currency = "CHF"
}
```


## WSDL 
`http://localhost:8888/ws/countries.wsdl`

## End-Point
`http://localhost:8888/ws`

## Request 
```xml
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
				  xmlns:gs="http://keepcalm.ch/web-services">
   <soapenv:Header/>
   <soapenv:Body>
      <gs:getCountryRequest>
         <gs:name>Switzerland</gs:name>
      </gs:getCountryRequest>
   </soapenv:Body>
</soapenv:Envelope>
```

## Call Service with `HTTPie`  {#httpieSoapCall}  

```bash
printf '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                                  xmlns:gs="http://keepcalm.ch/web-services">
   <soapenv:Header/>
   <soapenv:Body>
      <gs:getCountryRequest>
         <gs:name>Switzerland</gs:name>
      </gs:getCountryRequest>
   </soapenv:Body>
</soapenv:Envelope>'| http  --follow --timeout 3600 POST http://localhost:8888/ws \
 Content-Type:'text/xml'
```




# Implementation  {#implementation}   
## Router Table 
```kotlin
bean {
    router {
        "api".nest {
            GET("/lockdown/{name}") {
                val countryService = ref<CountryService>()
                ok().body(BodyInserters.fromValue(
                    countryService.getCountryByName(it.pathVariable("name")))
                )
            }
            GET("/easing/{name}") {
                val countryReactiveService = ref<CountryReactiveService>()
                ok().body(
                    BodyInserters.fromPublisher(countryReactiveService.getCountryByName(it.pathVariable("name")), GetCountryResponse::class.java)
                )
            }
        }
    }
}
```

## Reactive Service
```kotlin
@Service
class CountryReactiveService  (private val soapClient: SoapClient) {

    fun getCountryByName(name: String): Mono<GetCountryResponse> {
        return soapClient.getCountryReactive(name)
    }
}
```
## Reactive SOAP Client
`.subscribeOn(Schedulers.boundedElastic())`
```kotlin
fun getCountryReactive(country: String): Mono<GetCountryResponse> {
    val request = GetCountryRequest()
    request.name = country
    log.info("Requesting location for $country")
    return Mono.fromCallable {
        webServiceTemplate
            .marshalSendAndReceive("http://localhost:8888/ws/countries", request,
                SoapActionCallback(
                    "http://keepcalm.ch/web-services/GetCountryRequest")) as GetCountryResponse
    }
        // properly schedule above blocking call on
        // scheduler meant for blocking tasks
        .subscribeOn(Schedulers.boundedElastic())
}
```

[^AvoidingReactorMeltdown]: [Avoiding Reactor Meltdown](https://youtu.be/xCu73WVg8Ps?t=1)
[^Blockhound]: [Blockhound](https://github.com/reactor/BlockHound)
[^GitHub]: [kboot-flux-meets-soap](https://github.com/marzelwidmer/kboot-flux-meets-soap)
[^KotlinDSLinUnderAnhour]: [Kotlin DSL in under an hour](https://www.youtube.com/watch?v=zYNbsVv9oN0) | [Do Super Language with Kotlin](https://www.youtube.com/watch?v=hYXAFO3q3qU)

