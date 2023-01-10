# Third-party publisher sample - C#

Publish in proto (default) event format:

```sh
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_NAME=hello-custom-events-channel

dotnet run $PROJECT_ID $REGION $CHANNEL_NAME
```

Publish in text event format:

```sh
dotnet run $PROJECT_ID $REGION $CHANNEL_NAME true
```
