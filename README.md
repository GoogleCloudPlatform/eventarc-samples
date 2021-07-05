# Eventarc Samples

![Eventarc Logo](Eventarc-128-color.png)

[Eventarc](https://cloud.google.com/eventarc/) lets you asynchronously deliver
events from Google services, SaaS, and your own apps using loosely coupled
services that react to state changes. Eventarc requires no infrastructure
management — you can optimize productivity and costs while building a modern,
event-driven solution.

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

* [Image processing pipeline](processing-pipelines/image)
* [Image processing pipeline - Cloud Run for Anthos](processing-pipelines/image/image-processing-pipeline-eventarc-crfa.md)
* [BigQuery processing pipeline](processing-pipelines/bigquery)
* [BigQuery processing pipeline - Cloud Run for Anthos](processing-pipelines/bigquery/bigquery-processing-pipeline-eventarc-crfa.md)
* [Terraform sample](terraform)
* Eventarc and Workflows Integration
  * [Eventarc AuditLog-Cloud Storage and Workflows](eventarc-workflows-integration/eventarc-auditlog-storage)
  * [Eventarc Pub/Sub and Workflows](eventarc-workflows-integration/eventarc-pubsub)
  * [Workflows and Eventarc Pub/Sub](https://github.com/GoogleCloudPlatform/workflows-demos/tree/master/workflows-eventarc-integration/workflows-pubsub)
* [Expensive BigQuery jobs notifier with Eventarc and SendGrid](bigquery-jobs-notifier)

-------

This is not an official Google product.
