# Publisher sample - C# client library

### Publish

Run [publish.sh](publish.sh) to publish to the channel from C# client library
with the right event type and attributes.

```sh
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_NAME=hello-custom-events-channel

dotnet run $PROJECT_ID $REGION $CHANNEL_NAME
```
