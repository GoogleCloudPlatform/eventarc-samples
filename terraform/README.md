# Eventarc Terraform

This is a sample that shows how to use Terraform's
[eventarc_trigger](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/eventarc_trigger)
resource to create Eventarc triggers.

More specifically, this sample:

1. Enables Cloud Run and Eventarc APIs.
1. Deploys a publicly accessible Cloud Run service.
1. Creates an Eventarc Pub/Sub trigger for that service.
1. Creates an Eventarc AuditLog trigger for Cloud Storage events for that
   service.

## Terraform

Run the following commands inside [terraform](../terraform) folder.

1. Initialize terraform:

    ```sh
    terraform init
    ```

1. See the planned changes:

    ```sh
    terraform plan -var="project_id=YOUR-PROJECT-ID" -var="region=YOUR-GCP-REGION"
    ```

1. Create resources:

    ```sh
    terraform apply -var="project_id=YOUR-PROJECT-ID" -var="region=YOUR-GCP-REGION"
    ```

    Note: The AuditLog trigger might fail on the first try, if you just enabled
    Eventarc. In that case, `terraform apply` again.

1. Once resources are created, you can see the list of triggers:

    ```sh
    gcloud eventarc triggers list --location YOUR-GCP-REGION
    ```

1. Cleanup:

    ```sh
    terraform destroy -var="project_id=YOUR-PROJECT-ID" -var="region=YOUR-GCP-REGION"
    ```
