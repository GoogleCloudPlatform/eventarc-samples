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

Generate the GitHub and DevSite friendly formats to output folder:

```sh
dotnet run
```

## Run in a container

Build the container:

```sh
docker build -t eventlistgenerator .
```

Generate the GitHub and DevSite friendly format to output folder:

```sh
docker run -v $PWD/output:/app/output eventlistgenerator
```

## Run on a schedule with Cloud Run jobs

Run `setup.sh` to setup everything needed in your project to run the events list
generator as a Cloud Run job that runs on a schedule every day at 9am and
generates the GitHub and DevSite friendly formats in a public bucket.

Here are 2 files in a public bucket that get regenerated automatically every day:

* [README.md](https://storage.googleapis.com/events-atamel-event-list-generator/README.md)
* [README_devsite.md](https://storage.googleapis.com/events-atamel-event-list-generator/README_devsite.md)
