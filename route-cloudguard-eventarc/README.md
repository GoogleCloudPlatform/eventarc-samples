# Route Check Point CloudGuard Security Alerts to Google Cloud with Eventarc

> **Note:** **Check Point Cloud Guard as an event source** is an experimental
> feature in *preview*. Only allow-listed projects can currently take advantage
> of it. Please contact eventarc@google.com to get your project allow-listed
> before attempting this sample.

The [Check Point CloudGuard](https://www.checkpoint.com/cloudguard/) platform
provides you cloud native security, with advanced threat prevention for all your
assets and workloads in your public, private, hybrid or multi-cloud
environments.

In this sample, you'll see how to subscribe to events from Check Point
CloudGuard and route them to Google Cloud using Eventarc. More specifically:

1. Create a channel in Eventarc for CloudGuard.
1. Activate the channel in CloudGuard.
1. Create a notification in CloudGuard.
1. Deploy a workflow as event receiver.
1. Create an Eventarc trigger to connect CloudGuard to the workflow.
1. Test the configuration by triggering an event in CloudGuard.

## Enable APIs

Make sure your project id is set in `gcloud`:

```sh
PROJECT_ID=your-project-id
gcloud config set project $PROJECT_ID
```

Enable Eventarc APIs:

```sh
gcloud services enable \
  eventarc.googleapis.com \
  eventarcpublishing.googleapis.com
```

## Explore the CloudGuard provider and events in Eventarc

First, make sure your project has access to the CloudGuard provider:

```sh
gcloud eventarc providers list --filter='eventTypes.type~^cloudguard*'

NAME        LOCATION
cloudguard  asia-northeast1
cloudguard  europe-west4
cloudguard  us-central1
cloudguard  us-east1
cloudguard  us-west1
```

You can also see the events supported by the provider:

```sh
LOCATION=us-central1
gcloud eventarc providers describe cloudguard --location=$LOCATION

displayName: Check Point CloudGuard
eventTypes:
- type: cloudguard.v1.event
name: projects/your-project-id/locations/us-central1/providers/cloudguard
```

## Create a channel in Eventarc

Create a channel for CloudGuard events:

```sh
CHANNEL_ID=cloudguard-channel
gcloud eventarc channels create $CHANNEL_ID \
  --provider cloudguard \
  --location $LOCATION
```

Once channel is created, you'll see that it's in pending state:

```sh
gcloud eventarc channels describe $CHANNEL_ID \
  --location $LOCATION

activationToken: 9aK20NlRNP
createTime: '2023-01-19T08:02:47.504843441Z'
name: projects/your-project-id/locations/us-central1/channels/cloudguard-channel
provider: projects/your-project-id/locations/us-central1/providers/cloudguard
pubsubTopic: projects/your-project-id/topics/eventarc-channel-us-central1-cloudguard-channel-078
state: PENDING
uid: a56069cd-abd1-42d0-9511-823f6949bc9e
updateTime: '2023-01-19T08:02:53.481552764Z'
```

Save the `activationToken` and `name` of the channel. You will send them to
CloudGuard to get the channel activated:

```sh
ACTIVATION_TOKEN=$(gcloud eventarc channels describe $CHANNEL_ID --location $LOCATION --format='value(activationToken)')
CHANNEL_FULLNAME=$(gcloud eventarc channels describe $CHANNEL_ID --location $LOCATION --format='value(name)')
```

## Create an API key in CloudGuard

Before you can activate the channel, you need to create an API key in Check
Point CloudGuard.

1. Log into [Check Point portal](https://portal.checkpoint.com)
1. Go to `Settings` -> `Credentials`
1. Select `Create API Key` and save the `ID` and `Secret` of the API key:

```sh
ID=your-api-key-id
SECRET=your-api-key-secret
```

## Activate the channel by creating a channel connection in CloudGuard

[Create an Eventarc channel
connection](https://docs.cloudguard.dome9.com/reference/continuouscompliancenotification_createeventarcchannelconnection_post_v2compliancecontinuouscompliancenotificationeventarcchannelconnection)
in CloudGuard to activate the channel you created earlier:

```sh
curl -v --request POST \
    --url https://api.dome9.com/v2/Compliance/ContinuousComplianceNotification/eventarcChannelConnection \
    -u $ID:$SECRET \
    --header 'accept: application/json' \
    --header 'content-type: application/json' \
    --data @- << EOF
    {
      "activationToken": "$ACTIVATION_TOKEN",
      "channelFullName": "$CHANNEL_FULLNAME"
    }
EOF
```

If it's successful, you should see HTTP 200 and a channel connection id
returned:

```sh
< HTTP/1.1 200 OK
< Content-Type: application/json; charset=utf-8
< Content-Length: 38
...
* Connection #0 to host api.dome9.com left intact
"af094362-37da-4a42-ac73-882738406a45"
```

Make sure to save the channel connection id for later:

```sh
CHANNEL_CONNECTION_ID=af094362-37da-4a42-ac73-882738406a45
```

Also verify that the channel is now in `ACTIVE` state:

```sh
gcloud eventarc channels describe $CHANNEL_ID \
  --location $LOCATION

createTime: '2023-01-19T08:02:47.504843441Z'
name: projects/your-project-id/locations/us-central1/channels/cloudguard-channel
provider: projects/your-project-id/locations/us-central1/providers/cloudguard
pubsubTopic: projects/your-project-id/topics/eventarc-channel-us-central1-cloudguard-channel-078
state: ACTIVE
uid: a56069cd-abd1-42d0-9511-823f6949bc9e
updateTime: '2023-01-19T09:14:24.975138277Z'
```

## Create a notification handler in CloudGuard

Next, you need to set up a notification handler to watch for specific access
events in Check Point CloudGuard and forward notification of these events to
Eventarc. To create the notification:

```sh
NOTIFICATION_NAME=$CHANNEL_ID-notification

curl -v --request POST \
    --url https://api.dome9.com/v2/Compliance/ContinuousComplianceNotification \
    --header 'accept: application/json' \
    --header 'content-type: application/json' \
    -u $ID:$SECRET \
    --data @- << EOF
    {
    "changeDetection": {
        "eventarcData": {
            "channelConnectionId": "$CHANNEL_CONNECTION_ID"
        },
        "eventarcIntegrationState": "Enabled"
    },
    "name": "$NOTIFICATION_NAME"
    }
EOF
```

You will associate the notification handler with a ruleset later, once Eventarc
trigger is set up.

## Deploy a workflow as event receiver

Before testing the configuration, deploy an event receiver in Google Cloud. In
this case, a workflow that logs received events.

Enable Workflows related APIs:

```sh
gcloud services enable \
  workflows.googleapis.com \
  workflowexecutions.googleapis.com
```

Deploy the workflow defined in [workflow.yaml](workflow.yaml). The workflow
simply logs the received events:

```sh
WORKFLOW_NAME=cloudguard-events-logger

gcloud workflows deploy $WORKFLOW_NAME \
  --source=workflow.yaml --location=$LOCATION
```

## Create an Eventarc trigger

Create an Eventarc trigger to route events from Check Point CloudGuard to the
workflow.

You need a service account with the `eventarc.eventReceiver` role when creating
a trigger. You can either create a dedicated service account or use the default
compute service account. For simplicity, use the default compute service account
and make sure it has the `eventarc.eventReceiver` role:

```sh
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role roles/eventarc.eventReceiver
```

Create the trigger to connect CloudGuard channel to the workflow:

```sh
TRIGGER_NAME=cloudguard-workflows-trigger

gcloud eventarc triggers create $TRIGGER_NAME \
  --channel=$CHANNEL_ID \
  --destination-workflow=$WORKFLOW_NAME  \
  --location=$LOCATION \
  --event-filters=type=cloudguard.v1.event \
  --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com
```

## Associate notification handler with a ruleset in CloudGuard

The final step is to associate the notification handler it with a ruleset:

1. Log into [Check Point portal](https://portal.checkpoint.com)
1. Select `Posture management` > `Continuous posture`.
1. Add a ruleset, if you don't have any (eg. `GCP CloudGuard Best Practices` is
   a good one to try)
1. Select the checkbox next the ruleset  and click `Edit` on the top. This opens
   up a notifications list.
1. Select the checkbox next to the notification you created earlier
   (`cloudguard-channel-notification`) and click `Save`.

Now, every time there's a security event in this ruleset, it should send an
event to the notification handler we created which in turn will pass the event
to the Eventarc channel.

## Test

You can now test the entire configuration by accessing Check Point CloudGuard to
trigger a security event. You can then ensure that the event from Check Point
CloudGuard is routed to the workflow that logs the received event.

1. Log into [Check Point portal](https://portal.checkpoint.com)
1. Select `Posture management` > `Continuous posture`.
1. Click on the ruleset (`GCP CloudGuard Best Practices`) where we
   set the notification handler earlier.
1. Click `Run assessment`, select your Google Cloud project and click `Run`.

At the end of the assessment run, if there are violations, it should generate an
event for Eventarc. You can verify that workflow was executed by the received event:

```sh
gcloud workflows executions list $WORKFLOW_NAME
```

You can also see that the event is input to the workflow execution:

```log
{
  ...
  "datacontenttype": "application/json",
  "id": "10|Finding|-77|your-project-id|xImOEMo/O6J+dvXvsakVTQ|eventarc-channel-us-central1-your-channel-id-047",
  "severity": "High",
  "source": "//cloudguard",
  "specversion": "1.0",
  "subject": "CloudGuard Security Alert",
  "time": "2023-01-20T10:00:39.430146800Z",
  "title": "Ensure PubSub service is encrypted, with customer managed encryption keys.",
  "type": "cloudguard.v1.event"
}
```

**Note**: There seems to be a bug on event generation and you might not see events sometimes.
