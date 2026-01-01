# Spring Cloud Config property file generator
Spring Boot and Spring Cloud Config based property file generator
> Loads profiles from Spring Cloud Config server and generates a bootstrap.properties file.

## Dependencies
At least: Java 21 and Maven 3.5

Running: https://github.com/wlanboy/ServiceConfig

## Build 
mvn package -DskipTests=true

## Run property generator
java -jar target/cloudconfigpropertygenerator-0.0.1-SNAPSHOT.jar

## Konfigure property generator
vim bootstrap.properties

set proper values to:
spring.profiles.active, spring.application.name and PROPERTY_FILE_TO_WRITE.

It will load all properties for the given application name and properties and writes them to a java properties files.
This is a side car for Java applications which are not able to use Spring Boot (Java version < 8) but should still be able to be configured with a Spring Cloud Config server.

## Docker hub
https://hub.docker.com/repository/docker/wlanboy/propertygenerator
