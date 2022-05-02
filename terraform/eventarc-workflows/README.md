# Terraform with Eventarc and Workflows

This sample shows how to use Terraform's
[eventarc_trigger](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/eventarc_trigger)
and
[google_workflows_workflow](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workflows_workflow)
to deploy a workflow and create an Eventarc trigger to invoke it with a Pub/Sub event.

## Terraform

You can see [main.tf](main.tf) for Terraform and
[workflow.yaml](workflow.yaml] for Workflows definitions.

1. Initialize terraform:

    ```sh
    terraform init
    ```

1. See the planned changes:

    ```sh
    terraform plan -var="project_id=YOUR-PROJECT-ID" -var="region=YOUR-GCP-REGION"
    ```

1. Apply changes:

    ```sh
    terraform apply -var="project_id=YOUR-PROJECT-ID" -var="region=YOUR-GCP-REGION"
    ```

1. You can see the created workflow in the list:

    ```sh
    gcloud workflows list --location YOUR-GCP-REGION
    ```

1. You can also see the created trigger:

    ```sh
    gcloud eventarc triggers list --location YOUR-GCP-REGION
    ```

1. Cleanup:

    ```sh
    terraform destroy -var="project_id=YOUR-PROJECT-ID" -var="region=YOUR-GCP-REGION"
    ```

## Execute

You can execute the workflow using gcloud:

1. Find the topic of the trigger and send a message:

    ```sh
    TOPIC_ID=$(gcloud eventarc triggers describe trigger-pubsub-workflow-tf --location=YOUR-GCP-REGION --format='value(transport.pubsub.topic)')
    gcloud pubsub topics publish $TOPIC_ID --message="Hello World"
    ```

1. After sending the message, you can check Workflows output and logs to see the
   received `Hello World` message.
