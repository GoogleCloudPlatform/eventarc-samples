# Event List Generator

This generates a list of events supported by Eventarc.

The list has 2 parts: Pub/Sub and AuditLog.

* Pub/Sub list comes from `pubsub_services.json`.
* AuditLog list comes from the [AuditLog service
  catalog](https://raw.githubusercontent.com/googleapis/google-cloudevents/master/json/audit/service_catalog.json).

The list has 2 formats:

* GitHub friendly format is generated to `..\README.md`
* DevSite friendly format that is generated to `..\README_devsite.md`.

Generate the GitHub friendly format:

```sh
dotnet run
```

Generate the DevSite friendly format:

```sh
dotnet run --devsite true
```
