# Third party publisher sample - Node.js

This is a sample on how to use Eventarc publisher library with
CloudEvents SDK to publish an event to channel connection using Node.js.

Install dependencies:

```sh
npm install
```

Publish:

```sh
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_CONNECTION_ID=hello-channel-connection

npm run invoke projects/$PROJECT_ID/locations/$REGION/channelConnections/$CHANNEL_CONNECTION_ID
```
