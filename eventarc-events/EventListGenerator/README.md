# Event List Generator

This generates a list of events supported by Eventarc.

1. Direct and 3rd party list comes from `services.json`.
1. AuditLog list comes from the [AuditLog service
  catalog](https://raw.githubusercontent.com/googleapis/google-cloudevents/master/json/audit/service_catalog.json).

The list has 2 formats:

* GitHub friendly format is generated to [output/README.md](output/README.md).
* DevSite friendly format that is generated to [output/README_devsite.md](output/README_devsite.md).

## Run locally

Generate the GitHub and DevSite friendly formats to output folder using
`service.json` checked into GitHub:

```sh
dotnet run
```

Generate the GitHub and DevSite friendly formats to output folder using
`service.json` locally:

```sh
dotnet run true
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
generator as a Cloud Run job that runs on a schedule every Sunday, generates
the GitHub and DevSite friendly formats and checks into the [output](output)
folder.

If there's a change to the event list generator, run `update.sh` to build a new
container image, update the Cloud Run job and trigger the Cloud Scheduler to run
the new job.
