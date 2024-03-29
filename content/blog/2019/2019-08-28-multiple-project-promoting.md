---
title: Promoting Applications Across Environments
subTitle: Build and ship
date: "2019-09-18"
draft: false
tags: [k8s, CI/CD, Spring Boot]
categories: [k8s]
ShowToc: true
TocOpen: true
---

[//]: # (# Table of contents)

[//]: # (* [Create Project]&#40;{{<ref "#CreateProject" >}}&#41; )

[//]: # (* [Install Jenkins]&#40;{{<ref "#InstallJenkins" >}}&#41; / [Install Jenkins With CLI]&#40;{{<ref "#InstallJenkins" >}}&#41; )

[//]: # (* [Add Edit Role To ServiceAccount Jenkins]&#40;{{<ref "#AddEditRoleToServiceAccountJenkins" >}}&#41;  )

[//]: # (* [Add Role To Group]&#40;{{<ref "#AddRoleToGroup" >}}&#41;  )

[//]: # (* [Deploy Application]&#40;{{<ref "#DeployApplication" >}}&#41;)

[//]: # (* [Development Environment Deployment ]&#40;{{<ref "#DevelopmentEnvironmentDeployment" >}}&#41; )

[//]: # (* [Test API]&#40;{{<ref "#TestAPI" >}}&#41;)

[//]: # (* [Testing Environment Deployment]&#40;{{<ref "#TestingEnvironmentDeployment" >}}&#41;)

[//]: # (* [Production Environment Deployment]&#40;{{<ref "#ProductionEnvironmentDeployment" >}}&#41;)

[//]: # (* [Jenkins Pipeline]&#40;{{<ref "#JenkinsPipeline" >}}&#41; )

[//]: # (* [WebHooks]&#40;{{<ref "#WebHooks" >}}&#41;)


## Create Project  {#CreateProject} 
We are going to use the CLI to create some projects. 
Let's create our projects first:
```bash
$ oc login  
$ oc new-project development --display-name="Development Environment"
$ oc new-project testing --display-name="Testing Environment"    
$ oc new-project production --display-name="Production Environment"    
$ oc new-project jenkins --display-name="Jenkins CI/CD"  
```

## Install Jenkins  {#InstallJenkins}   
Create a Jenkins in the `Jenkins CI/CD` project with some storage. Take the Jenkins from the catalog and set some more memory and volume capacity on it.
Everything else we let the default values. 
Login with your Openshift account to the `Jenkins BlueOcean`.  

![Jenkins-From-Catalog-1](/static/multiple-project-promoting/Jenkins-from-catalog-1.png)
![Jenkins-From-Catalog-2](/static/multiple-project-promoting/Jenkins-from-catalog-2.png)
![Jenkins-From-Catalog-3](/static/multiple-project-promoting/Jenkins-from-catalog-3.png)

## Configure Jenkins Maven Slave - Concurrency Limit
Let's configure out `Maven-Slave` concurrency limit to `5` in order that we later want build more then one project.
Please go to the Jenkins Configuration Page `https://<jenkins>/configure` in the section `Cloud/Kubernetes Pod Template` and search for the `Maven` Pod.

![Maven-Pod-Concurrency-Limit](/static/multiple-project-promoting/Maven-Pod-Concurrency-Limit.png)


## Install Jenkins with CLI {#InstallJenkinsWithCLI}    
```bash
$ oc new-app jenkins-persistent --name jenkins --param ENABLE_OAUTH=true \
        --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi -n jenkins
``` 


### Jenkins File From Source Repository
The pipeline [Jenkinsfile](https://raw.githubusercontent.com/marzelwidmer/marzelwidmer.github.io/master/img/2019/multiple-project-promoting/Promotion-Jenkinsfile) is provided in the source repository. 

## Add Edit Role To ServiceAccount Jenkins  {#AddEditRoleToServiceAccountJenkins}   
Let’s add in RBAC to our projects to allow the different service accounts to build, pro‐ mote, and tag images.
First we will allow the cicd project’s Jenkins service account edit access to all of our projects:

```bash
$ oc policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n development
$ oc policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n testing
$ oc policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n production
```

## Add Role To Group  {#AddRoleToGroup}     
That we can pull our image from `testing` and `production` environment from the `development` registry. This is needed for pulling the Images across the projects.

```bash
$ oc policy add-role-to-group system:image-puller system:serviceaccounts:testing  \
        -n development
$ oc policy add-role-to-group system:image-puller system:serviceaccounts:production \
        -n development
```

# Deploy Application  {#DeployApplication}     
Let's deploy first the application with the [S2i strategy](https://docs.openshift.com/container-platform/3.11/creating_images/s2i.html).
before we will create the delivery pipeline.
## Development Environment Deployment  {#DevelopmentEnvironmentDeployment} 
Let's change first the project to to development with the `oc project development` command.

```bash
$ oc project development

Now using project "development" on server "https://console.c3smonkey.ch:8443".

Creat a new app with `oc new-app`
```

We will use here the [fabric8/s2i-java](https://hub.docker.com/r/fabric8/s2i-java) to deploy our application and will point it to the master branch with the command `oc new-app`
We also want expose the service `oc expose svc/catalog-service` to get a URL with the command `oc get route catalog-service` we will see the URL on the terminal. 

```bash
$ oc new-app fabric8/s2i-java:latest-java11~https://github.com/marzelwidmer/catalog-service.git#master; \
    oc expose svc/catalog-service; \
    oc get route catalog-service

--> Found Docker image 6414174 (7 weeks old) from Docker Hub for "fabric8/s2i-java:latest-java11"

  Java Applications
  -----------------
  Platform for building and running plain Java applications (fat-jar and flat classpath)

  Tags: builder, java

  * An image stream tag will be created as "s2i-java:latest-java11" that will track the source image
  * A source build using source code from https://github.com/marzelwidmer/catalog-service.git#master will be created
    * The resulting image will be pushed to image stream tag "catalog-service:latest"
    * Every time "s2i-java:latest-java11" changes a new build will be triggered
  * This image will be deployed in deployment config "catalog-service"
  * Ports 8080/tcp, 8778/tcp, 9779/tcp will be load balanced by service "catalog-service"
    * Other containers can access this service through the hostname "catalog-service"

--> Creating resources ...
    imagestream.image.openshift.io "s2i-java" created
    imagestream.image.openshift.io "catalog-service" created
    buildconfig.build.openshift.io "catalog-service" created
    deploymentconfig.apps.openshift.io "catalog-service" created
    service "catalog-service" created
--> Success
    Build scheduled, use 'oc logs -f bc/catalog-service' to track its progress.
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/catalog-service'
    Run 'oc status' to view your app.
route.route.openshift.io/catalog-service exposed
NAME             HOST/PORT                                      PATH  SERVICES         PORT      TERMINATION  WILDCARD
catalog-service  catalog-service-development.apps.c3smonkey.ch        catalog-service  8080-tcp               None
```

Now take a look in the OpenShift Console project `development`

![catalog-service-dev-deployment](/static/multiple-project-promoting/catalog-service-dev-deployment.png)

Let's take a look what the S2i crated for us. 
This can be done with the following command `oc get all -n development --selector app=catalog-service`.

```bash
$ oc get all -n development --selector app=catalog-service                                  

NAME                          READY   STATUS    RESTARTS   AGE
pod/catalog-service-1-2rv5r   1/1     Running   0          56m

NAME                                      DESIRED   CURRENT   READY   AGE
replicationcontroller/catalog-service-1   1         1         1       56m

NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/catalog-service   ClusterIP   172.30.216.240   <none>        8080/TCP,8778/TCP,9779/TCP   57m

NAME                                                 REVISION   DESIRED   CURRENT   TRIGGERED BY
deploymentconfig.apps.openshift.io/catalog-service   1          1         1         config,image(catalog-service:latest)

NAME                                             TYPE     FROM         LATEST
buildconfig.build.openshift.io/catalog-service   Source   Git@master   1

NAME                                         TYPE     FROM          STATUS     STARTED             DURATION
build.build.openshift.io/catalog-service-1   Source   Git@b49dff4   Complete   About an hour ago   1m10s

NAME                                             DOCKER REPO                                                    TAGS            
imagestream.image.openshift.io/catalog-service   docker-registry.default.svc:5000/development/catalog-service   latest           
imagestream.image.openshift.io/s2i-java          docker-registry.default.svc:5000/development/s2i-java          latest-java11   

NAME                                       HOST/PORT                                       PATH   SERVICES          PORT        WILDCARD
route.route.openshift.io/catalog-service   catalog-service-development.apps.c3smonkey.ch          catalog-service   8080-tcp    None
```


## Test API on Development  {#TestAPI} 
Now let's test the amazing `/api/v1/animals/rando` API from `catalog-service` by hitting the following Rest endpoint 50 times. 
in a bash shell with the following command. `for x in (seq 50); http "http://catalog-service-development.apps.c3smonkey.ch/api/v1/animals/random"; end`
```bash
$ ~ 🐠 
for x in (seq 50); \
     http "http://catalog-service-development.apps.c3smonkey.ch/api/v1/animals/random"; \
end                                                                               

HTTP/1.1 200 OK
Cache-control: private
Content-Length: 14
Content-Type: text/plain;charset=UTF-8
Set-Cookie: 1e5e1500c4996e7978ef9efb67d863a1=1e12d12873c24c5c17782f3da537ed6a; path=/; HttpOnly

Burrowing Frog

HTTP/1.1 200 OK
Cache-control: private
Content-Length: 14
Content-Type: text/plain;charset=UTF-8
Set-Cookie: 1e5e1500c4996e7978ef9efb67d863a1=1e12d12873c24c5c17782f3da537ed6a; path=/; HttpOnly

Dogo Argentino

HTTP/1.1 200 OK
```
 
## Testing Environment Deployment {#TestingEnvironmentDeployment}
Let's change first to the testing project with `oc project testing`. 
We remember that we have in our setup only one docker registry from this registry we want promote our Docker images to other projects in our OpenShift Cluster setup.
The access is now available because we did the [Add Role To Group](#AddRoleToGroup). Now let's take a look at the ImageStream in the project `development` with the
following command `oc get is -n development` we will get the docker registry we need to create the a deployment configuration in the project `testing`. We are searching for the 
`catalog-service` docker registry.

```bash
$ oc get is -n development
NAME              DOCKER REPO                                                    TAGS            UPDATED
catalog-service   docker-registry.default.svc:5000/development/catalog-service   latest          About an hour ago
s2i-java          docker-registry.default.svc:5000/development/s2i-java          latest-java11   About an hour ago
```
 
Now let's create a deployment configuration for the `promoteQA` tag with `oc create dc catalog-service --image=docker-registry.default.svc:5000/development/catalog-service:promoteQA` 
Our Jenkins pipeline is configured to interact with this tag to promote between the environments. 
```bash
$ oc create dc catalog-service --image=docker-registry.default.svc:5000/development/catalog-service:promoteQA
deploymentconfig.apps.openshift.io/catalog-service created
```

Now we have to expose the `dc/catalog-service` with the port `8080` who our Spring Boot App is running on.  
This easy done with the `oc expose dc catalog-service --port=8080` command.
```bash
$ oc expose dc catalog-service --port=8080
service/catalog-service exposed
```

Now also expose the service and get the route `oc expose service catalog-service --name=catalog-service; oc get route`
```bash
$ oc expose service catalog-service --name=catalog-service; oc get route
route.route.openshift.io/catalog-service exposed
NAME              HOST/PORT                                   PATH   SERVICES          PORT   TERMINATION   WILDCARD
catalog-service   catalog-service-testing.apps.c3smonkey.ch          catalog-service   8080                 None
```

We have to patch the `dc` `imagePullPolicy` from `IfNotPresent` to `Always` with `oc patch` command. The default is set to `IfNotPresent`, 
but we wish to always trigger a deployment when we tag a new image
```bash
$ oc patch dc/catalog-service  -p \
      '{"spec":{"template":{"spec":{"containers":[{"name":"default-container","imagePullPolicy":"Always"}]}}}}'
```


## Production Environment Deployment {#ProductionEnvironmentDeployment}
The same what we did on the [Testing Environment Deployment ](#TestingEnvironmentDeployment) we also do now on the production environment. 
But we configure the promotion tag `promotePRD` in the deployment configuration.

```bash
$ oc project production
$ oc create dc catalog-service --image=docker-registry.default.svc:5000/development/catalog-service:promotePRD
$ oc patch dc/catalog-service  -p \
     '{"spec":{"template":{"spec":{"containers":[{"name":"default-container","imagePullPolicy":"Always"}]}}}}'
$ oc expose dc catalog-service --port=8080
$ oc expose svc/catalog-service
```

## Jenkins Pipeline  {#JenkinsPipeline}  

So now let's create a `BuildConfig` for the `catalaog-service` with the 
following [catalog-service-jenkins-pipeline](/multiple-project-promoting/catalog-service-pipeline.yaml) configuration
in the Jenkins namespace (project) let's do it with `oc create -n jenkins -f https://blog.marcelwidmer.org/openshift-pipeline/catalog-service-pipeline.yaml`

```bash
$ oc create -n jenkins -f \
    https://blog.marcelwidmer.org/openshift-pipeline/catalog-service-pipeline.yaml
buildconfig.build.openshift.io/catalog-service-pipeline created
```

When you go now in the OpenShift [Console](https://console.c3smonkey.ch:8443/console/project/jenkins/browse/pipelines) in the project `Jenkins` in the section.
`Builds/Pipelines` you will something like this.
![Catalog Service Pipeline](/static/multiple-project-promoting/catalog-service-pipeline-created.png)


### Run Jenkins Pipeline 
Now is time to run the pipeline with the command `oc start-build catalog-service-pipeline -n jenkins` 

```bash
$ oc start-build catalog-service-pipeline -n jenkins
build.build.openshift.io/catalog-service-pipeline-1 started
```

After a while you will see something like this. For production deployment we configured our pipeline with a approvable step.

![Catalog Service Pipeline approvable](/static/multiple-project-promoting/catalog-service-pipeline-approvable.png)

Now is time to approve the application and hit the 
After the approve button in the pipeline to deploy to the production namespace.

![Catalog Service Pipeline success](/static/multiple-project-promoting/catalog-service-pipeline-success.png)


## WebHooks  {#WebHooks}  
Now let's creat a WebHook. So when we push something in our `catalog-service` the pipeline start run. 
Change first to the `jenkins` project again with `oc project jenkins`
```bash
$ oc project jenkins
Now using project "jenkins" on server "https://console.c3smonkey.ch:8443"
```

Now check the `Buildconfig` with `oc describe bc/catalog-service-pipeline`
```bash
$ oc describe bc/catalog-service-pipeline                                                                                                                                               
Name:		catalog-service-pipeline
Namespace:	jenkins
Created:	2 hours ago
Labels:		app=catalog-service-pipeline
		name=catalog-service-pipeline
Annotations:	<none>
Latest Version:	1

Strategy:		JenkinsPipeline
URL:			https://github.com/marzelwidmer/catalog-service.git
Ref:			master
Jenkinsfile path:	Jenkinsfile

Build Run Policy:	Serial
Triggered by:		<none>
Builds History Limit:
	Successful:	5
	Failed:		5

Build				Status		Duration	Creation Time
catalog-service-pipeline-1 	complete 	8m12s 		2019-09-05 13:54:18 +0200 CEST

Events:	<none>
```

At the moment we don't have any GitHub Hooks configured.


## BuildConfig Triggers
With the following command you can set GitHub WebHook trigger. This will create a secret for us and configured a WebHook in our BuildConfig.
```bash
$ oc set triggers bc/catalog-service-pipeline --from-github 
```

When we run again the `oc describe bc/catalog-service-pipeline` command we will see that we have a `bc` like below. 
```bash
$ oc describe bc/catalog-service-pipeline                                                                                                                                             
Name:		catalog-service-pipeline
Namespace:	jenkins
Created:	2 hours ago
Labels:		app=catalog-service-pipeline
		name=catalog-service-pipeline
Annotations:	<none>
Latest Version:	1

Strategy:		JenkinsPipeline
URL:			https://github.com/marzelwidmer/catalog-service.git
Ref:			master
Jenkinsfile path:	Jenkinsfile

Build Run Policy:	Serial
Triggered by:		<none>
Webhook GitHub:
	URL:	https://okd.ch/apis/build.openshift.io/v1/namespaces/jenkins/buildconfigs/catalog-service-pipeline/webhooks/<secret>/github
Builds History Limit:
	Successful:	5
	Failed:		5

Build				Status		Duration	Creation Time
catalog-service-pipeline-1 	complete 	8m12s 		2019-09-05 13:54:18 +0200 CEST

Events:	<none>
```

> **_Note:_** The URL <secret> we will replace with a secret. This is just an place holder in the URL.
https://console.c3smonkey.ch:8443/apis/build.openshift.io/v1/namespaces/jenkins/buildconfigs/catalog-service-pipeline/webhooks/<secret>/github

To grab the `<secret>` we have to replace in the URL you can call the following command.   
```bash
$ oc get bc/catalog-service-pipeline -o json | jq '.spec.triggers[].github.secret'
```

In your GitHub repository, select Add Webhook from Settings → Webhooks.
Paste the URL output (similar to above) into the Payload URL field.

> **_Hint:_** `SSL Disable (not recommended)` if your cluster don't have a valid SSL certificate.
SSL verification
 By default, we verify SSL certificates when delivering payloads.


![Add GitHub WebHook](/static/multiple-project-promoting/Add-GitHub-WebHook.png)
![GitHub WebHooks](/static/multiple-project-promoting/GitHub-WebHooks.png)


> **_References:_**  
>   [https://blog.openshift.com/decrease-maven-build-times-openshift-pipelines-using-persistent-volume-claim/](https://blog.openshift.com/decrease-maven-build-times-openshift-pipelines-using-persistent-volume-claim/) 
>   [https://github.com/redhat-cop/container-pipelines/tree/master/basic-spring-boot](https://github.com/redhat-cop/container-pipelines/tree/master/basic-spring-boot)   
