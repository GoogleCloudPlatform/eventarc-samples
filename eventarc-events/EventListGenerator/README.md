# Event List Generator

This generates a list of events supported by Eventarc.

The list has 4 parts:

1. Direct list comes from `direct_services.json`.
1. AuditLog list comes from the [AuditLog service
  catalog](https://raw.githubusercontent.com/googleapis/google-cloudevents/master/json/audit/service_catalog.json).
1. Pub/Sub list comes from `pubsub_services.json`.
1. 3rd party list comes from `thirdparty_services.json`.

The list has 2 formats:

* GitHub friendly format is generated to `output/README.md`
* DevSite friendly format that is generated to `output/README_devsite.md`.

## Run locally

Generate the GitHub friendly format to output folder:

```sh
dotnet run
```

Generate the DevSite friendly format:

```sh
dotnet run --devsite true
```

Generate in a different folder:

```sh
dotnet run --folder .
```

## Run in a container

Build the container:

```sh
docker build -t eventlistgenerator .
```

Generate the GitHub friendly format to output folder:

```sh
docker run -v $PWD/output:/app/output eventlistgenerator
```

Generate the DevSite friendly format:

```sh
docker run -v $PWD/output:/app/output eventlistgenerator --devsite true
```
