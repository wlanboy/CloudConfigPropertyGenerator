# Spring Cloud Config property file generator
Spring Boot and Spring Cloud Config based property file generator to migrate from Spring Cloud Config Server.
Loads profiles from Spring Cloud Config server and generates a Kubernetes Config Map.


## Dependencies
At least: Java 21 and Maven 3.5

Running: https://github.com/wlanboy/ServiceConfig

## Build 
```bash
mvn package
```

## Konfigure property generator
```bash
vim bootstrap.properties
```

## Run property generator
```bash
java -jar target/cloudconfigpropertygenerator-0.0.1-SNAPSHOT.jar
```

## build docker image
```bash
docker build -t propertygenerator:latest . --build-arg JAR_FILE=./target/cloudconfigpropertygenerator-0.0.1-SNAPSHOT.jar
```

## run docker image
```bash
mkdir output

docker run --rm \
  -v $(pwd)/application.properties:/application.properties \
  -v $(pwd)/bootstrap.properties:/bootstrap.properties \
  -v $(pwd)/output:/output \
  -e CONFIGMAP_FILE_TO_WRITE=/output/configmap.yaml \
  wlanboy/propertygenerator:latest
```

## output
```sh
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.5.9)

2026-01-02T06:50:16.017Z  INFO 1 --- [sample] [           main] c.c.c.ConfigServicePropertySourceLocator : Fetching config from server at : http://172.17.0.1:8888
2026-01-02T06:50:17.521Z  INFO 1 --- [sample] [           main] c.c.c.ConfigServicePropertySourceLocator : Located environment: name=sample, profiles=[test,info], label=null, version=8c615ecc77bb90db13306c1f8ae42c7839b106ee, state=
2026-01-02T06:50:17.523Z  INFO 1 --- [sample] [           main] b.c.PropertySourceBootstrapConfiguration : Located property source: [BootstrapPropertySource {name='bootstrapProperties-configClient'}, BootstrapPropertySource {name='bootstrapProperties-https://github.com/wlanboy/cloudconfig.git/application-info.yaml'}, BootstrapPropertySource {name='bootstrapProperties-https://github.com/wlanboy/cloudconfig.git/sample.yaml'}]
2026-01-02T06:50:17.554Z  INFO 1 --- [sample] [           main] .CloudconfigpropertygeneratorApplication : The following 2 profiles are active: "test", "info"
2026-01-02T06:50:18.254Z  INFO 1 --- [sample] [           main] o.s.cloud.context.scope.GenericScope     : BeanFactory id=04d02a29-f860-3431-808e-48a13550e717
2026-01-02T06:50:18.653Z  INFO 1 --- [sample] [           main] .CloudconfigpropertygeneratorApplication : Started CloudconfigpropertygeneratorApplication in 4.215 seconds (process running for 4.993)
2026-01-02T06:50:18.657Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Merging all properties from Spring Environment
2026-01-02T06:50:18.658Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Reading PropertySource: bootstrapProperties-configClient
2026-01-02T06:50:18.661Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Reading PropertySource: bootstrapProperties-https://github.com/wlanboy/cloudconfig.git/application-info.yaml
2026-01-02T06:50:18.662Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Reading PropertySource: bootstrapProperties-https://github.com/wlanboy/cloudconfig.git/sample.yaml
2026-01-02T06:50:18.663Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Reading PropertySource: Config resource 'file [application.properties]' via location 'optional:file:./'
2026-01-02T06:50:18.663Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Reading PropertySource: springCloudClientHostInfo
2026-01-02T06:50:18.663Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Reading PropertySource: applicationConfig: [file:./application.properties]
2026-01-02T06:50:18.663Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Reading PropertySource: applicationInfo
2026-01-02T06:50:18.664Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Reading PropertySource: Config resource 'file [bootstrap.properties]' via location 'optional:file:./'
2026-01-02T06:50:18.664Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Reading PropertySource: applicationConfig: [file:./bootstrap.properties]
2026-01-02T06:50:18.664Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Reading PropertySource: springCloudDefaultProperties
2026-01-02T06:50:18.666Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Writing ConfigMap to /output/configmap.yaml
2026-01-02T06:50:18.671Z  INFO 1 --- [sample] [           main] c.w.c.PropertyGenerator                  : Finished generating Kubernetes ConfigMap
```

## Docker hub
https://hub.docker.com/repository/docker/wlanboy/propertygenerator
