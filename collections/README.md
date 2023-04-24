# Metadata Lake Service
---------

## Environment:

This service requires a postgresql instance to be up and running with a database already created. For convenience a
docker-compose script can be found in 'docker/'. Execute the following command to stand up a postgresql instance:

````
docker-compose up -d
````

The instance will listen on port '5432' (exposed to the host). A database called 'stg' is created, along with user '
stg_user' using the password 'stg_password'.

## To run from IntelliJ:

Run ``com.collibra.metalake.service.application.Application`` with the following environment variables:

````
METALAKE_DGC_URL=
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/stg
SPRING_DATASOURCE_USERNAME=stg_user
SPRING_DATASOURCE_PASSWORD=stg_password
FORCE_STANDARD_LOGS=true
````

## To run as a docker container:

````
./gradlew jibDockerBuild metalake/service:my_version
````

````
docker run -p 8080:8080 -e FORCE_STANDARD_LOGS=true -e DB_JDBC_URL=[url] -e DB_USER=[user] -e DB_PASSWORD=[password] -it metalake/service:my_version
````

-----
For example, if running locally using the Dockerized postgresql instance, the following command can be used:

````
docker run -p "8080:8080" -e DB_JDBC_URL="jdbc:postgresql://[host IP]/stg" -e DB_USER="stg_user" -e DB_PASSWORD="stg_password" -it metalake/service:my_version
````

## OAS Documentation:

Navigate to: ``http://[host]:[port]/docs/index.html``

## Dictionary

* The dictionary can be initialized by invoking the REST endpoint via the POST method: dictionary/provision
* Providers can be created by invoking the REST endpoint via the POST method: dictionary/provider. Refer to the OAS
  documentation for the payload.
* Providers can be retrieved by invoking the REST endpoint via the GET method: dictionary/providers.

## Search

* The asset search can be invoked by invoking the REST endpoint via the POST method: search/providers. Refer to the OAS
  documentation for the payload.

## Running integration tests

If you are using Docker Desktop for Mac 2.4.x or higher, ensure `Use gRPC FUSE for file sharing` from the General
settings panel is disabled
(read more [here](https://github.com/testcontainers/testcontainers-java/issues/3291)).

## Local sonar analysis

To have the ability to check sonarqube locally you will have to run your own server. This can easily be done with:
`docker run -d --name sonarqube -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true -p 9000:9000 sonarqube:latest`

When the container is booted and configured, you can run the actual check with:
```
./gradlew sonarqube \
  -Dsonar.projectKey=com.collibra.metalake:metalake-service \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login={KEY_GENERATED_BY_SERVER}
```
## Local telemetry/tracing analysis
To view trace data locally:

1. Enable the agent:
   1. If working with a helm deployment, ensuring the `otel: enabled` property is set is all that's needed (this should already be done)
   2. If working through IntelliJ:
      1. running `./gradlew jibDockerBuild` to generate a copy of the opentelemetry java agent jar in the `build/jib` directory.
      2. supply `OTEL_JAVAAGENT_ENABLED` as an environment variable, set to `true`
      3. pass the following flags:
      ```
         -javaagent:/Users/<path-to-mdl-service>/metalake-service/build/jib/agent/otel-javaagent.jar
         -Dotel.instrumentation.jdbc-datasource.enabled=false
         -Dotel.instrumentation.servlet-filter.enabled=true
         -Dotel.instrumentation.servlet-service.enabled=true

2. From the `.compose_telemetry` folder, run `docker-compose -f telemetry.yaml up -d`

Tracing information will be visible in the Jaeger UI interface on `http://localhost:16686`.
