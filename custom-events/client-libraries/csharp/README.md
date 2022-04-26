# Publisher sample - C#

Example invocation:

```sh
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_NAME=hello-custom-events-channel

dotnet run $PROJECT_ID $REGION $CHANNEL_NAME
```
