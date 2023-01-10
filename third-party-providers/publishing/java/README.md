# Third party publisher sample - Java

Example invocation:

```sh
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_CONNECTION_ID=hello-channel-connection

./gradlew run --args="$PROJECT_ID $REGION $CHANNEL_CONNECTION_ID"
```
