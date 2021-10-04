# Eventarc (Pub/Sub) and Workflows

> **Note:** Eventarc Workflows destination is currently a feature in *private preview*.
> Only allow-listed projects can currently take advantage of it. Please fill out
> [this form](https://docs.google.com/forms/d/e/1FAIpQLSdgwrSV8Y4xZv_tvI6X2JEGX1-ty9yizv3_EAOVHWVKXvDLEA/viewform?resourcekey=0-1ftfaZAk_IS2J61P6r1mSw)
> to get your project allowlisted before attempting this sample.

In this sample, you will see how to connect
[Eventarc](https://cloud.google.com/eventarc/docs) events to
[Workflows](https://cloud.google.com/workflows/docs) directly.

More specifically, you will create an Eventarc Pub/Sub trigger to listen for
messages to a Pub/Sub topic and pass them onto a workflow.

## Deploy a workflow

First, create a [workflow.yaml](workflow.yaml). It logs the received
CloudEvent and decodes the Pub/Sub message inside.

```yaml
main:
    params: [event]
    steps:
        - log_event:
            call: sys.log
            args:
                text: ${event}
                severity: INFO
        - decode_pubsub_message:
            assign:
            - base64: ${base64.decode(event.data.data)}
            - message: ${text.decode(base64)}
        - return_pubsub_message:
                return: ${message}
```

Deploy the workflow:

```sh
WORKFLOW_NAME=eventarc-pubsub-workflow

gcloud workflows deploy $WORKFLOW_NAME --source=workflow.yaml
```

## Create a service account

Create a service account for Eventarc trigger to use to invoke Workflows.

```sh
PROJECT_ID=$(gcloud config get-value project)
SERVICE_ACCOUNT=eventarc-pubsub-workflow-sa

gcloud iam service-accounts create $SERVICE_ACCOUNT
```

Assign the service account Workflows Invoker role:

```sh
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
  --role "roles/workflows.invoker"
```

## Create an Eventarc Pub/Sub trigger

Connect a Pub/Sub topic to the workflow by creating an Eventarc Pub/Sub
trigger:

```sh
TRIGGER_NAME=trigger-pubsub-workflow

gcloud eventarc triggers create $TRIGGER_NAME \
  --location=us-central1 \
  --destination-workflow=$WORKFLOW_NAME \
  --destination-workflow-location=us-central1 \
  --event-filters="type=google.cloud.pubsub.topic.v1.messagePublished" \
  --service-account=$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
```

Find out the Pub/Sub topic that Eventarc created:

```sh
TOPIC=$(basename $(gcloud eventarc triggers describe $TRIGGER_NAME --format='value(transport.pubsub.topic)'))
```

## Trigger the workflow

Send a message to the Pub/Sub topic to trigger the workflow:

```sh
gcloud pubsub topics publish $TOPIC --message="Hello Workflows"
```

In the logs, you should see that the workflow received the Pub/Sub
message, decoded it and returned as output.
