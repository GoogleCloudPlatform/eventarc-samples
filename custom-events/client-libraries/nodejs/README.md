# Publisher sample - Node.js

This is a sample on how to use Eventarc publisher library with
CloudEvents SDK to publish an event to a custom channel using Node.js.

Install dependencies:

```sh
npm install
```

Publish:

```sh
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_NAME=hello-custom-events-channel

npm run invoke projects/$PROJECT_ID/locations/$REGION/channels/$CHANNEL_NAME
```
