# Image processing pipeline v2 - Eventarc (Cloud Storage) + Cloud Run + Workflows

In this sample, we'll build an image processing pipeline to read Google Cloud
Storage events with **Eventarc** and pass to a set of **Cloud Run** and **Cloud
Functions** services orchestrated by **Workflows**.

![Image Processing Pipeline](image-processing-pipeline-v2.png)

1. An image is saved to an input bucket that generates a Cloud Storage create
   event.
2. Cloud Storage create event is read by Eventarc via an Cloud Storage trigger
   and passed to a Filter service.
3. Filter is a Cloud Run service. It receives and parses the Cloud Storage event
   wrapped into a CloudEvent. It uses Vision API to determine if the image is
   safe. If the image is safe, it starts a Workflows execution with the bucket
   and file details.
4. In first step of workflow, Labeler, a Cloud Function service, extracts labels
   of the image with Vision API and saves the labels to the output bucket.
5. In second step, Resizer, another Cloud Function service, resizes the image using
   [ImageSharp](https://github.com/SixLabors/ImageSharp) and saves to the
   resized image to the output bucket.
6. In the last step, Watermarker, a another Cloud Function service, adds a
   watermark of labels from Labeler to the resized image using
   [ImageSharp](https://github.com/SixLabors/ImageSharp) and saves the image to
   the output bucket.

## Before you begin

Before deploying services and triggers, go through some setup steps.

### Set project id

Make sure that the project id is setup:

```sh
gcloud config set project [YOUR-PROJECT-ID]
PROJECT_ID=$(gcloud config get-value project)
```

### Enable APIs

Enable all necessary services:

```sh
gcloud services enable \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  vision.googleapis.com \
  workflows.googleapis.com \
  workflowexecutions.googleapis.com
```

### Region, location, platform

Set region, location and platform for Cloud Run and Eventarc:

```sh
REGION=us-central1

gcloud config set run/region $REGION
gcloud config set run/platform managed
gcloud config set eventarc/location $REGION
```

### Configure service accounts

Default compute service account will be used in triggers. Grant the
`eventarc.eventReceiver` role to the default compute service account:

```sh
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role roles/eventarc.eventReceiver
```

Grant the `pubsub.publisher` role to the Cloud Storage service account. This is
needed for the Eventarc Cloud Storage trigger:

```sh
SERVICE_ACCOUNT="$(gcloud storage service-agent --project ${PROJECT_NUMBER})"

gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
    --member serviceAccount:${SERVICE_ACCOUNT} \
    --role roles/pubsub.publisher
```

If you enabled the Pub/Sub service account on or before April 8, 2021, grant the
`iam.serviceAccountTokenCreator` role to the Pub/Sub service account:

```sh
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
  --role roles/iam.serviceAccountTokenCreator
```

## Create storage buckets

Create 2 unique storage buckets to save pre and post processed images.

```sh
BUCKET1=$PROJECT_ID-images-input
BUCKET2=$PROJECT_ID-images-output
gcloud storage buckets create gs://$BUCKET1 --location $REGION
gcloud storage buckets create gs://$BUCKET2 --location $REGION
```

## Watermarker

This Cloud Functions service receives the bucket, file and labels information, reads the
file, adds the labels as watermark to the image using
[ImageSharp](https://github.com/SixLabors/ImageSharp) and saves the image to the
output bucket.

The code of the service is in [watermarker](watermarker) folder.

Inside the top level [processing-pipelines](..) folder, deploy the service:

```sh
SERVICE_NAME=watermarker
gcloud functions deploy $SERVICE_NAME \
  --allow-unauthenticated \
  --runtime dotnet3 \
  --trigger-http \
  --set-env-vars BUCKET=$BUCKET2 \
  --entry-point Watermarker.Function \
  --set-build-env-vars GOOGLE_BUILDABLE=image-v2/watermarker/csharp
```

Set the service URL in an env variable, we'll need later:

```sh
WATERMARKER_URL=$(gcloud functions describe $SERVICE_NAME --format 'value(httpsTrigger.url)')
```

## Resizer

This Cloud Functions service receives the bucket and file information, resizes
the image using [ImageSharp](https://github.com/SixLabors/ImageSharp) and saves
the image to the output bucket.

The code of the service is in [resizer](resizer) folder.

Inside the top level [processing-pipelines](..) folder, deploy the service:

```sh
SERVICE_NAME=resizer
gcloud functions deploy $SERVICE_NAME \
  --allow-unauthenticated \
  --runtime dotnet3 \
  --trigger-http \
  --set-env-vars BUCKET=$BUCKET2 \
  --entry-point Resizer.Function \
  --set-build-env-vars GOOGLE_BUILDABLE=image-v2/resizer/csharp
```

Set the service URL in an env variable, we'll need later:

```sh
RESIZER_URL=$(gcloud functions describe $SERVICE_NAME --format 'value(httpsTrigger.url)')
```

## Labeler

This Cloud Functions service receives the bucket and file information, extracts
labels of the image with Vision API and saves the labels to the output bucket.

The code of the service is in [labeler](labeler) folder.

Inside the top level [processing-pipelines](..) folder, deploy the service:

```sh
SERVICE_NAME=labeler
gcloud functions deploy $SERVICE_NAME \
  --allow-unauthenticated \
  --runtime dotnet3 \
  --trigger-http \
  --set-env-vars BUCKET=$BUCKET2 \
  --entry-point Labeler.Function \
  --set-build-env-vars GOOGLE_BUILDABLE=image-v2/labeler/csharp
```

Set the service URL in an env variable, we'll need later:

```sh
LABELER_URL=$(gcloud functions describe $SERVICE_NAME --format 'value(httpsTrigger.url)')
```

## Workflow

Create a workflow to bring together Labeler, Resizer and Watermarker services.
This workflow will be triggered by the Filter service.

### Define

Create a [workflow.yaml](workflow.yaml).

In the `init` step, the workflow will read bucket and file info along with a map
of URLs for Labeler, Resizer and Watermarker services:

```yaml
main:
  params: [args]
  steps:
  - init:
      assign:
        - bucket: ${args.bucket}
        - file: ${args.file}
        - urls: ${args.urls}
```

In the `label` step, Workflows make a call to Labeler and captures the response
of response (top 3 labels):

```yaml
  - label:
      call: http.post
      args:
        url: ${urls.LABELER_URL}
        auth:
          type: OIDC
        body:
            bucket: ${bucket}
            file: ${file}
      result: labelResponse
```

Same with the `resize` step. The resize response is the bucket and name of the
resized image:

```yaml
  - resize:
      call: http.post
      args:
        url: ${urls.RESIZER_URL}
        auth:
          type: OIDC
        body:
            bucket: ${bucket}
            file: ${file}
      result: resizeResponse
```

In the `watermark` step, the resized image gets a watermark from the labels:

```yaml
  - watermark:
      call: http.post
      args:
        url: ${urls.WATERMARKER_URL}
        auth:
          type: OIDC
        body:
            bucket: ${resizeResponse.body.bucket}
            file: ${resizeResponse.body.file}
            labels: ${labelResponse.body.labels}
      result: watermarkResponse
```

In the `final` step, the HTTP codes from each step is returned:

```yaml
  - final:
      return:
        label: ${labelResponse.code}
        resize: ${resizeResponse.code}
        watermark: ${watermarkResponse.code}
```

### Deploy

Deploy the workflow:

```sh
WORKFLOW_NAME=image-processing
gcloud workflows deploy $WORKFLOW_NAME \
    --source=workflow.yaml
```

## Filter

This Cloud Run service receives Cloud Storage create events for saved images via
an Eventarc trigger. It uses Vision API to determine if the image is safe.
If the image is safe, it starts a Workflows execution with the bucket and file details.

### Service

The code of the service is in [filter](filter) folder.

Inside the top level [processing-pipelines](..) folder, build and push the
container image:

```sh
SERVICE_NAME=filter
docker build -t gcr.io/$PROJECT_ID/$SERVICE_NAME -f image-v2/$SERVICE_NAME/csharp/Dockerfile .
docker push gcr.io/$PROJECT_ID/$SERVICE_NAME
```

Deploy the service:

```sh
gcloud run deploy $SERVICE_NAME \
  --allow-unauthenticated \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --set-env-vars PROJECT_ID=$PROJECT_ID,REGION=$REGION,WORKFLOW_NAME=$WORKFLOW_NAME,LABELER_URL=$LABELER_URL,RESIZER_URL=$RESIZER_URL,WATERMARKER_URL=$WATERMARKER_URL
```

### Trigger

The trigger of the service filters for new file creation events form the input
Cloud Storage bucket.

Create the trigger:

```sh
TRIGGER_NAME=trigger-$SERVICE_NAME
gcloud eventarc triggers create $TRIGGER_NAME \
     --destination-run-service=$SERVICE_NAME \
     --destination-run-region=$REGION \
     --event-filters="type=google.cloud.storage.object.v1.finalized" \
     --event-filters="bucket=$BUCKET1" \
     --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com
```

## Test the pipeline

To test the pipeline, upload an image to the input bucket:

```sh
gcloud storage cp beach.jpg gs://$BUCKET1
```

After a minute or so, you should see resized, watermarked and labelled image in
the output bucket:

```sh
gcloud storage ls gs://$BUCKET2

gs://events-atamel-images-output/beach-400x400-watermark.jpeg
gs://events-atamel-images-output/beach-400x400.png
gs://events-atamel-images-output/beach-labels.txt
```
