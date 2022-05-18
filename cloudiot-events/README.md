# Cloud IoT Events

> **Note:** Eventarc Cloud IoT events is feature in *preview*.
> Only allow-listed projects can currently take advantage of it. Please contact
> eventarc@google.com to get your project allow-listed before attempting this sample.

In this sample, you'll see how to read Cloud IoT events directly (without having
to go through Audit Logs).

## Events supported

These are the Cloud IoT events supported.

[Device](https://cloud.google.com/iot/docs/reference/cloudiot/rest#rest-resource:-v1.projects.locations.registries.devices) Events:

* google.api.cloud.iot.v1.deviceCreated
* google.api.cloud.iot.v1.deviceUpdated
* google.api.cloud.iot.v1.deviceDeleted

[Registry](https://cloud.google.com/iot/docs/reference/cloudiot/rest#rest-resource:-v1.projects.locations.registries) Events:

* google.api.cloud.iot.v1.registryCreated
* google.api.cloud.iot.v1.registryUpdated
* google.api.cloud.iot.v1.registryDeleted

## Before you begin

Make sure your project id is set in gcloud:

```sh
gcloud config set project PROJECT_ID
```

## Setup

Run `./setup.sh` to enable required services, create a service account with the
right role, deploy a Cloud Run service to receive events and create a trigger
with the service account to route Cloud IoT device registry events to the Cloud
Run service.

## Test

Run `./test.sh` to create a Cloud IoT device registry and see the received event
in Cloud Run service logs.
