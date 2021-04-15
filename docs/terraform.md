# Eventarc Terraform

This is a sample that shows how to use Terraform's
[eventarc_trigger](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/eventarc_trigger)
module to create Eventarc triggers.

More specifically, this sample:

1. Enables Cloud Run and Eventarc APIs.
1. Deploys a publicly accessible Cloud Run service.
1. Creates an Eventarc Pub/Sub trigger for that service.
1. Creates an Eventarc AuditLog trigger for Cloud Storage events for that
   service.

## Before you start

This sample assumes that the default Compute Engine service account has the
`eventarc.eventReceiver` role. If not, you can grant it as follows:

```sh
export PROJECT_NUMBER="$(gcloud projects list --filter=$(gcloud config get-value project) --format='value(PROJECT_NUMBER)')"

gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
    --member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
    --role='roles/eventarc.eventReceiver'
```

## Terraform

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
