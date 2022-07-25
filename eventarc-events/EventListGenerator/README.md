# Event List Generator

This generates a list of events supported by Eventarc.

The list has 3 parts: Pub/Sub, AuditLog, Direct services.

* Direct list comes from `direct_services.json`.
* AuditLog list comes from the [AuditLog service
  catalog](https://raw.githubusercontent.com/googleapis/google-cloudevents/master/json/audit/service_catalog.json).
* Pub/Sub list comes from `pubsub_services.json`.
* 3rd party list comes from `thirdparty_services.json`.

The list has 2 formats:

* GitHub friendly format is generated to `output/README.md`
* DevSite friendly format that is generated to `output/README_devsite.md`.

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

Build the container:

```sh
docker build -t eventlistgenerator .
```

Run as a container:

```sh
docker run -v $PWD/output:/app/output eventlistgenerator
```
