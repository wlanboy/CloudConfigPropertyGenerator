# Spring Cloud Config property file generator
Spring Boot based property file generator

## Dependencies
At least: Java 8 and Maven 3.5

Running: https://github.com/wlanboy/ServiceRegistry

Running: https://github.com/wlanboy/ServiceConfig

## Build Simple CosmosDB Client 
mvn package -DskipTests=true

## Run property generator
java -jar target/cloudconfigpropertygenerator-0.0.1-SNAPSHOT.jar

## Konfigure property generator
vim bootstrap.properties

set proper values to:
spring.profiles.active, spring.application.name and PROPERTY_FILE_TO_WRITE.
