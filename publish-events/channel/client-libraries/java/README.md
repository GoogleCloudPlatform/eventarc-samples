# Publisher sample - Java

Publish in proto (default) event format:

```sh
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_NAME=hello-custom-events-channel

./gradlew run --args="$PROJECT_ID $REGION $CHANNEL_NAME"
```

Publish in text event format:

```sh
./gradlew run --args="$PROJECT_ID $REGION $CHANNEL_NAME true"
```
