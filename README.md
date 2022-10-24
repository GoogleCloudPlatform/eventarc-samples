# Eventarc Samples

![Eventarc Logo](Eventarc-128-color.png)

[Eventarc](https://cloud.google.com/eventarc/) lets you asynchronously deliver
events from different event sources (Google Cloud sources with Audit Logs, Cloud
Storage buckets and Pub/Sub topics) to different event consumers (Cloud Run
services, Cloud Functions, Workflows and GKE services).

This repository contains a collection of samples for Eventarc for various use
cases.

Here is the [the list of events supported by Eventarc](eventarc-events).

## Slides

There's a
[presentation](https://speakerdeck.com/meteatamel/eventarc-trigger-cloud-run-services-with-events-from-google-cloud)
that explains Eventarc.

<!-- [![Eventarc presentation](./eventarc-trigger-cloud-run-services-with-events-from-google-cloud.png)](https://speakerdeck.com/meteatamel/eventarc-trigger-cloud-run-services-with-events-from-google-cloud) -->

<a href="https://speakerdeck.com/meteatamel/eventarc-trigger-cloud-run-services-with-events-from-google-cloud">
    <img alt="Eventarc presentation" src="eventarc-trigger-cloud-run-services-with-events-from-google-cloud.png" width="50%" height="50%">
</a>

## Samples

* Eventarc and Cloud Run
  * [BigQuery processing pipeline](processing-pipelines/bigquery)
  * [Image processing pipeline v1 - Eventarc (AuditLog-Cloud Storage) + Cloud Run](processing-pipelines/image-v1)
  * [Expensive BigQuery jobs notifier](bigquery-jobs-notifier/run)
  * [Compute Engine VM Labeler](gce-vm-labeler/run)
* Eventarc and Google Kubernetes Engine (GKE)
  * [Trigger Kubernetes services with Eventarc events](eventarc-gke/trigger-gke-eventarc-events)
  * [Trigger Kubernetes services with Eventarc events (Terraform)](terraform/eventarc-gke/trigger-gke-eventarc-events/)
* Eventarc and Cloud Run for Anthos
  * [BigQuery processing pipeline](processing-pipelines/bigquery/bigquery-processing-pipeline-eventarc-crfa.md)
  * [Image processing pipeline v1 - Eventarc (AuditLog-Cloud Storage) + Cloud Run for Anthos](processing-pipelines/image-v1/image-processing-pipeline-eventarc-crfa.md)
* Eventarc and Cloud Functions (2nd gen)
  * [Compute Engine VM Labeler](gce-vm-labeler/gcf)
  * [Expensive BigQuery jobs notifier](bigquery-jobs-notifier/gcf)
* Eventarc and Workflows
  * [Eventarc (AuditLog-BigQuery) and Workflows](eventarc-workflows-integration/eventarc-auditlog-bigquery)
  * [Eventarc (Cloud Storage) and Workflows](eventarc-workflows-integration/eventarc-storage)
  * [Eventarc (AuditLog-Cloud Storage), Cloud Run and Workflows](eventarc-workflows-integration/eventarc-auditlog-storage-cloudrun)
  * [Eventarc (Pub/Sub) and Workflows](eventarc-workflows-integration/eventarc-pubsub)
  * [Eventarc (Pub/Sub), Cloud Run and Workflows](eventarc-workflows-integration/eventarc-pubsub-cloudrun)
  * [Workflows and Eventarc (Pub/Sub)](https://github.com/GoogleCloudPlatform/workflows-demos/tree/master/workflows-eventarc-integration/workflows-pubsub)
  * [Image processing pipeline v2 - Eventarc (Cloud Storage) + Cloud Run + Workflows](processing-pipelines/image-v2/)
  * [Image processing pipeline v3 - Eventarc (Cloud Storage) + Workflows](processing-pipelines/image-v3/)
  * [Take screenshots of webpages with Cloud Run jobs, Workflows and Eventarc](https://github.com/GoogleCloudPlatform/workflows-demos/blob/master/screenshot-jobs)
  * [Event payload storer](https://github.com/GoogleCloudPlatform/workflows-demos/tree/master/workflows-eventarc-integration/event-payload-storer)
* Terraform samples
  * [Basic Terraform](terraform/basic)
  * [Terraform with Eventarc and Workflows](terraform/eventarc-workflows)
  * [Trigger Kubernetes services with Eventarc events (Terraform)](terraform/eventarc-gke/trigger-gke-eventarc-events/)
* [Cross project eventing](cross-project-eventing)
* [Custom events samples](custom-events)
* [Cloud IoT Events](cloudiot-events)

-------

This is not an official Google product.
