# Eventarc (Cloud Storage) and Workflows

> **Note:** Eventarc Workflows destinatio is currently a feature in *private preview*.
> Only allowlisted projects can currently take advantage of it. Please fill out
> [this form](https://docs.google.com/forms/d/e/1FAIpQLSdgwrSV8Y4xZv_tvI6X2JEGX1-ty9yizv3_EAOVHWVKXvDLEA/viewform?resourcekey=0-1ftfaZAk_IS2J61P6r1mSw)
> to get your project allowlisted before attempting this sample.

In this sample, you will see how to connect
[Eventarc](https://cloud.google.com/eventarc/docs) events to
[Workflows](https://cloud.google.com/workflows/docs) directly.

More specifically, you will create an Eventarc Cloud Storage trigger to listen
for new object creations events in a bucket and pass them onto a workflow.

## Deploy a workflow

First, create a [workflow.yaml](workflow.yaml). It logs the received
CloudEvent and logs the bucket and object info.

```yaml
main:
    params: [event]
    steps:
        - log_event:
            call: sys.log
            args:
                text: ${event}
                severity: INFO
        - extract_bucket_object:
            assign:
            - bucket: ${event.data.bucket}
            - object: ${event.data.name}
        - return_bucket_object:
                return:
                    bucket: ${bucket}
                    object: ${object}
```

Deploy the workflow:

```sh
WORKFLOW_NAME=eventarc-storage-workflow

gcloud workflows deploy $WORKFLOW_NAME --source=workflow.yaml
```

## Create a service account

Create a service account for Eventarc trigger to use to invoke Workflows.

```sh
PROJECT_ID=$(gcloud config get-value project)
SERVICE_ACCOUNT=eventarc-storage-workflow-sa

gcloud iam service-accounts create $SERVICE_ACCOUNT
```

Assign the service account Workflows Invoker role:

```sh
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
  --role "roles/workflows.invoker"
```

## Create an Eventarc Cloud Storage trigger

First, create a bucket:

```sh
BUCKET=$PROJECT_ID-eventarc-workflows

gsutil mb -l us-central1 gs://$BUCKET
```

Create an Eventarc Cloud Storage trigger:

```sh
TRIGGER_NAME=trigger-storage-workflow

gcloud eventarc triggers create $TRIGGER_NAME \
  --location=us-central1 \
  --destination-workflow=$WORKFLOW_NAME \
  --destination-workflow-location=us-central1 \
  --event-filters="type=google.cloud.storage.object.v1.finalized" \
  --event-filters="bucket=$BUCKET" \
  --service-account=$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
```

## Trigger the workflow

Create a file in the bucket to trigger the workflow:

```sh
echo "Hello World" > random.txt
gsutil cp random.txt gs://$BUCKET/random.txt
```

In the logs, you should see that the workflow received the Cloud Storage event.
