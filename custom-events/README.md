# Eventarc Custom Events Sample

> **Note:** Eventarc Custom Events is an experimental feature in *preview*.
> Only allow-listed projects can currently take advantage of it. Please contact
> eventarc@google.com to get your project allow-listed before attempting this sample.

In this sample, you'll see how to:

1. How to create a channel to publish events to.
1. How to create a service and trigger to receive events from that channel.
1. How to publish events to that channel from gcloud, curl and client libraries.

## Before you begin

Make sure your project id is set in gcloud:

```sh
gcloud config set project PROJECT_ID
```

## Create a channel, a service and a trigger

Run `./setup.sh` to do create a channel to publish events to, to deploy a Cloud
Run service to receive events and to create a trigger to connect channel to the
service.

### Publish from gcloud

Run `./publish_gcloud.sh` to publish to the channel from gcloud with the right
event type and attributes.

### Publish from curl

Run `./publish_curl.sh` to publish to the channel from curl with the right
event type and attributes.

### Publish from client libraries

You can also publish events from client libraries. Here's an example run for C#:

```sh
cd client-libraries/csharp
./publish.sh
```
