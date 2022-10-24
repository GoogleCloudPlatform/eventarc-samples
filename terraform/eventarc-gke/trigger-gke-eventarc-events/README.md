# Trigger Kubernetes services with Eventarc events (Terraform)

Similar to [Trigger Kubernetes services with Eventarc
events](../../../eventarc-gke/trigger-gke-eventarc-events/) sample, in this
sample, you will see how to trigger Kubernetes services running on Google
Kubernetes Engine (GKE) with Eventarc events. The difference is you will setup
the GKE cluster and Eventarc triggers using Terraform.

## Before you begin

First, make sure you have a Google Cloud project and the project id is set in
`gcloud`:

```sh
PROJECT_ID=your-project-id
gcloud config set project $PROJECT_ID
```

## Create a GKE cluster

Go to [./terraform/gke](./terraform/gke) folder and initialize Terraform:

```sh
cd terraform/gke
terraform init
```

Take a look at  [main.tf](./terraform/gke/main.tf). It enables required services
for GKE and creates a GKE cluster.

Plan for changes with your project id and region:

```sh
terraform plan -var="project_id=eventarc-terraform" -var="region=us-central1" -var="cluster_name=eventarc-cluster"
```

Apply changes:

```sh
terraform apply -var="project_id=eventarc-terraform" -var="region=us-central1" -var="cluster_name=eventarc-cluster"
```

Make sure the cluster creation is finished before moving onto the next step.

## Deploy a GKE service

To deploy a GKE service, we'll rely on `kubectl` instead (as Terraform does not
handle resource drift, potentially missing out on a key benefit of Kubernetes,
which is its continuous reconciling from desired state to actual state).

Go to [.scripts/](./scripts) folder and run
[deploy_gke_service.sh](scripts/deploy_gke_service.sh) to deploy Cloud Run's
[hello container](https://github.com/GoogleCloudPlatform/cloud-run-hello) as a
Kubernetes service on GKE. This service logs received HTTP requests and CloudEvents.

Make sure the pod is running:

```sh
kubectl get pods

NAME                        READY   STATUS
hello-gke-df6469d4b-5vv22   1/1     Running
```

And the service is running:

```sh
kubectl get svc

NAME         TYPE           CLUSTER-IP    EXTERNAL-IP
hello-gke    LoadBalancer   10.51.1.26    <none>
```

## Set up Eventarc

Go to [./terraform/eventarc](./terraform/eventarc) folder and initialize Terraform:

```sh
cd terraform/eventarc
terraform init
```

Take a look at  [main.tf](./terraform/eventarc/main.tf). It enables required services
for Eventarc, initialize Eventarc GKE destinations.

Plan for changes with your project id and region:

```sh
terraform plan -var="project_id=eventarc-terraform" -var="region=us-central1"
```

Apply changes:

```sh
terraform apply -var="project_id=eventarc-terraform" -var="region=us-central1"
```

## Create a Pub/Sub trigger

### Create a trigger

Go to [./terraform/pubsub-trigger](./terraform/pubsub-trigger) folder and initialize Terraform:

```sh
cd terraform/eventarc
terraform init
```

Take a look at  [main.tf](./terraform/pubsub-trigger/main.tf). It creates a
service account for Eventarc triggers and creates a Pub/Sub trigger to the
deployed GKE service.

Plan for changes with your project id and region:

```sh
terraform plan -var="project_id=eventarc-terraform" -var="region=us-central1" -var="cluster_name=eventarc-cluster"
```

Apply changes:

```sh
terraform apply -var="project_id=eventarc-terraform" -var="region=us-central1" -var="cluster_name=eventarc-cluster"
```

### Test the trigger

Run [test_eventarc_pubsub.sh](scripts/test_eventarc_pubsub.sh) to find the
underlying Pub/Sub topic for the trigger and send a message to that topic.

To check if the event is received, first, find the pod id:

```sh
kubectl get pods

NAME                        READY   STATUS
hello-gke-df6469d4b-5vv22   1/1     Running
```

Check the logs of the pod:

```sh
kubectl logs hello-gke-df6469d4b-5vv22

{
  "severity": "INFO",
  "eventType": "google.cloud.pubsub.topic.v1.messagePublished",
  "message": "Received event of type google.cloud.pubsub.topic.v1.messagePublished. Event data: Hello World",
  "event": {
    "data": {
      "subscription": "projects/atamel-eventarc-gke/subscriptions/eventarc-us-central1-trigger-pubsub-gke-sub-270",
      "message": {
        "data": "SGVsbG8gV29ybGQ=",
        "messageId": "6031025573654834",
        "publishTime": "2022-10-19T14:13:07.990Z"
      }
    },
    "datacontenttype": "application/json",
    "id": "6031025573654834",
    "source": "//pubsub.googleapis.com/projects/atamel-eventarc-gke/topics/eventarc-us-central1-trigger-pubsub-gke-729",
    "specversion": "1.0",
    "time": "2022-10-19T14:13:07.99Z",
    "type": "google.cloud.pubsub.topic.v1.messagePublished"
  }
}
```
