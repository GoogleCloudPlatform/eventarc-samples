# Compute Engine VM Labeler

In this sample, you'll build a Cloud Run service that receives a notification
when a Compute Engine VM instance is created with Eventarc. In response, it adds
a label to the newly created VM, specifying the creator of the VM.

## Determine newly created Compute Engine VMs

Compute Engine emits 2 AuditLogs when a VM is created.

The first one is emitted at the beginning of VM creation as looks like this:

![GCE AuditLog](gce-auditlog1.png)

The second one is emitted after the VM creation and looks like this:

![GCE AuditLog](gce-auditlog2.png)

Notice the `operation` field with `first:true` and `last:true` values. The
second AuditLog contains all the information we need to label an instance,
therefore we will use `last:true` flag to detect it in Cloud Run.

## Before you begin

Before deploying the service and trigger, go through some setup steps.

### Default Compute service account

Default compute service account will be used in the Audit Log trigger of Eventarc. Grant the
`eventarc.eventReceiver` role to the default compute service account:

```sh
export PROJECT_NUMBER="$(gcloud projects describe $(gcloud config get-value project) --format='value(projectNumber)')"

gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
    --member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
    --role='roles/eventarc.eventReceiver'
```

### Region, location, platform

Set region, location and platform for Cloud Run and Eventarc:

```sh
export REGION=us-central1
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set run/platform managed
gcloud config set run/region ${REGION}
gcloud config set eventarc/location ${REGION}
```

## GCE VM Labeler

This service receives AuditLogs for service `compute.googleapis.com` and
method `beta.compute.instances.insert` to detect newly created VMs. Then, it
checks the received AuditLog if it's the last one in the sequence by checking
the `last:true` flag in `operation` field. If so, it extracts the relevant info from
the AuditLog such as project id, zone, instance id and uses Compute Engine API
to label the instance with the username of the creator.

The source code of the service is in [csharp](csharp) folder.

Inside the source folder, build and push the container image:

```sh
SERVICE_NAME=gce-vm-labeler
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME
```

Deploy the service:

```sh
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --allow-unauthenticated
```

## Trigger

Once the service is deployed, create a trigger to filter for the right events:

```sh
gcloud eventarc triggers create $SERVICE_NAME-trigger \
  --destination-run-service=$SERVICE_NAME \
  --destination-run-region=$REGION \
  --event-filters="type=google.cloud.audit.log.v1.written" \
  --event-filters="serviceName=compute.googleapis.com" \
  --event-filters="methodName=beta.compute.instances.insert" \
  --service-account=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
```

Before testing, make sure the trigger is ready:

```sh
gcloud eventarc triggers list

NAME                                ACTIVE
gce-vm-labeler-trigger              Yes
```

## Test

To test, you need to create a Compute Engine VM in Cloud Console (You can also
create VMs with `gcloud` but it does not seem to generate AuditLogs).

Once the VM creation completes, you should see the added `username` label on the VM in the
Cloud Console or using the following command:

```sh
gcloud compute instances describe my-instance

...
labelFingerprint: ULU6pAy2C7s=
labels:
  username: atameldev
...
```
