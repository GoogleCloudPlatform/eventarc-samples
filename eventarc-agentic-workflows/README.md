# Eventarc Agentic Workflows

This repository contains a sample project demonstrating how to deploy and manage
[**Eventarc**](https://docs.cloud.google.com/eventarc/docs) driven agentic
workflows on Google Cloud Platform, as shown at
[Google Cloud Next 2026](https://www.googlecloudevents.com/next-vegas/).

![The log-events service showing the flow of events through the Eventarc Message
Bus.](log-events.png)

# Demo Deployment & Execution

## 1. Prerequisites

To deploy this sample (on Linux/macOS), you need:

*   **Google Cloud SDK**: Install the
    [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) and
    authenticate:

    ```bash
    gcloud auth login
    gcloud auth application-default login
    ```

*   **Terraform**: Follow the official
    [Terraform installation instructions](https://developer.hashicorp.com/terraform/install).

### Windows Compatibility

The deployment scripts and commands in this repository are written for Bash and
are designed for Linux/macOS. To run them on Windows, it is recommended to use
[WSL (Windows Subsystem for Linux)](https://learn.microsoft.com/en-us/windows/wsl/about).

## 2. Project Setup (One-Time Execution)

This demo is deployed over 2 GCP projects. Before deploying infrastructure, you
need to create these projects and perform some one-time setup on each project.

To make it easy to copy and paste the commands below, set these environment
variables in your terminal (replace with your actual values):

```bash
# These projects will be created in a later section, or you can re-use
# existing projects.
export PROJECT_ID=<your-main-project-id>
export PROJECT_ID_EXT=<your-external-project-id>

# This is the name of a Google Cloud Storage (GCS) bucket which will be
# created in a later step. This bucket is needed to hold the Terraform state.
export TFSTATE_BUCKET=<your-tfstate-bucket>

# Resources in the demo will be created in this region.
export REGION="us-central1"

# New projects will need to be linked with a billing account.
# Find with: gcloud billing accounts list
export BILLING_ACCOUNT_ID=<your-billing-account-id> # e.g., 012345-567890-ABCDEF
```

> [!NOTE]
>
> The selected `$REGION` must be supported by Eventarc Advanced. See
> [Eventarc locations](https://docs.cloud.google.com/eventarc/docs/locations)
> for supported regions.

### Main Project: `$PROJECT_ID`

If you already have a project, you can re-use it. If not, create the project and
link a billing account as follows:

```bash
gcloud projects create $PROJECT_ID
gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID
```

The principal deploying the configuration (e.g., your user account) needs
permissions to create and manage service accounts, grant IAM roles, enable APIs,
and create resources in the Main Project `$PROJECT_ID`. Broadly, **Project
Owner** or **Project Editor** combined with **Project IAM Admin** is required to
allow Terraform to:

-   Enable required APIs (Eventarc, Cloud Run, Cloud Build, Agent
    Platform/Vertex AI, Artifact Registry).
-   Create Service Accounts for agents and invokers.
-   Grant IAM permissions (e.g., Eventarc Message Bus User, Vertex AI User,
    Cloud Run Invoker).
-   Create the Eventarc Message Bus, Artifact Registry, and Cloud Run services.

> [!NOTE]
>
> The user who creates the project is automatically granted the Owner role. If
> someone else created the project for you, ensure they grant you the **Editor**
> and **Project IAM Admin** roles:
>
> ```bash
> gcloud projects add-iam-policy-binding $PROJECT_ID --member="user:YOUR_EMAIL" --role="roles/editor"
> gcloud projects add-iam-policy-binding $PROJECT_ID --member="user:YOUR_EMAIL" --role="roles/resourcemanager.projectIamAdmin"
> ```

### External Project: `$PROJECT_ID_EXT`

As before, you are free to re-use an existing project. If not, create a new
project and link a billing account:

```bash
gcloud projects create $PROJECT_ID_EXT
gcloud billing projects link $PROJECT_ID_EXT --billing-account=$BILLING_ACCOUNT_ID
```

Similar to the Main Project, you will need permissions to create resources and
manage IAM in the project `$PROJECT_ID_EXT`. **Project Owner** or **Project
Editor** with **Project IAM Admin** is required to allow Terraform to:

-   Create Service Accounts for external services.
-   Grant IAM permissions (e.g., Cloud Run Invoker).
-   Deploy Cloud Run services and Eventarc Pipelines/Enrollments targeting them.

### Setup Remote State Bucket

To share Terraform state across machines and prevent resource duplication
conflicts, create a Google Cloud Storage (GCS) bucket in the Main Project to
house the state file.

```bash
gcloud storage buckets create gs://$TFSTATE_BUCKET --project=$PROJECT_ID --location=$REGION
```

## 3. Configuration

1.  Copy the example configuration file:

    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```

2.  Edit `terraform.tfvars` and replace the placeholders with your actual
    project IDs, bucket name, and region, as configured earlier in
    [Project Setup](#2-project-setup-one-time-execution):

    ```hcl
    workspace_projects = {
      demo     = <your-main-project-id>
      external = <your-external-project-id>
    }
    region = "us-central1"
    bucket = <your-tfstate-bucket>
    ```

### Set Environment Variables

To make it easy to copy and paste some commands below, and to run an agent
locally (see [Local Development](#local-development--testing) section), you must
set relevant environment variables.

You can source the `prep_env.sh` script, which extracts the necessary
environment variables from `terraform.tfvars`:

```bash
source prep_env.sh
```

## 4. Deployment

We use Terraform to deploy all components in the demo. You can deploy the full
demo stack using a single command:

```bash
./deploy.sh all
```

> [!NOTE]
>
> Visit the [Troubleshooting](#troubleshooting) section in case you run into
> issues.

<details>

<summary>Step-by-step deployment</summary>

We have separated the common infrastructure from the service-specific
deployments.

1.  **Infrastructure:**

    First, deploy the shared infrastructure (Message Bus, Artifact Registry,
    etc.) located in the `/infra` directory:

    ```bash
    ./deploy.sh infra external.yaml demo.yaml
    ```

2.  **External Services:**

    After the shared infrastructure is deployed, you must first deploy the
    external services defined in `external.yaml`:

    ```bash
    ./deploy.sh external
    ```

3.  **Demo Services:**

    After the external services are deployed, you can deploy your main demo
    services specified in `demo.yaml`:

    ```bash
    ./deploy.sh demo
    ```

</details>

### Cleanup

To destroy all resources created by this project, you can use the `--destroy`
flag with the deployment scripts. You will need to manually approve each
destruction step.

```bash
./deploy.sh all --destroy
```

<details>

<summary>Destroy specific components (reverse order):</summary>

If you want to destroy components individually, you should do so in the reverse
order of deployment:

1.  **Demo Services:** `./deploy.sh demo --destroy`
2.  **External Services:** `./deploy.sh external --destroy`
3.  **Infrastructure:** `./deploy.sh infra --destroy external.yaml demo.yaml`

</details>

## 5. Running the Demo

Ensure you have [Set Environment Variables](#set-environment-variables) before
running the commands below.

### Open the Live Event Feed

1.  Run the following command to proxy the `log-events` service:

    ```bash
    gcloud run services proxy log-events --region=$REGION --project=$PROJECT_ID_EXT --port=8080
    ```

2.  Navigate to http://127.0.0.1:8080

### Open the Storefront

1.  Run the following command to proxy the `store` service (which provides the
    Storefront UI):

    ```bash
    gcloud run services proxy store --region=$REGION --project=$PROJECT_ID --port=8081
    ```

2.  Navigate to http://127.0.0.1:8081

### Make Orders & Observe Events

Use the Storefront UI to place an order. Observe events as they flow through the
Eventarc feed in the Live Event Feed UI.

# Adding New Services and Agents

The project structure supports adding arbitrary services and agents under the
`services/` directory.

## Adding a Generic Service

You can add any service (not necessarily an ADK agent) under the `services/`
directory. To add a new service:

1.  Create a directory for your service under `services/` (e.g.,
    `services/my_custom_service`).
2.  Add a `Dockerfile` in that directory that describes how to build your
    service.

    > [!IMPORTANT]
    >
    > The build system (both Cloud Build for production and `run_local.py` for
    > local testing) runs from the **repository root**. Your `Dockerfile` must
    > assume the build context is the root directory and use paths relative to
    > the root (e.g., `COPY services/shared_tools /app/shared_tools/`).

3.  Update `demo.yaml` in the config directory to define the new service and
    point `src_dir` to your new directory (e.g., `services/my_custom_service`).

## Adding a New Agent

To add a new agent:

1.  Create a directory under `services/agents/` (or use
    `services/agents/adk_a2a_agent` as a template).
2.  Ensure it has a `Dockerfile` as described above.
3.  Update `demo.yaml` in the config directory to define the new service and
    point `src_dir` to your new directory (e.g.,
    `services/agents/my_new_agent`).

# Local Development & Testing

This optional section pertains to running agents locally, using the agent Web
UI, running evaluations, and manually invoking agents.

Ensure you have [Set Environment Variables](#set-environment-variables) before
running the commands below.

<details>

<summary><b>Local Development Setup</b></summary>

## Prerequisites

*   **Docker**: Follow the
    [official Docker installation instructions](https://docs.docker.com/get-docker/).

*   **Python**: Ensure [Python >=3.12](https://www.python.org/downloads/) is
    installed.

## Virtual Environment

Run the following commands in the root of the repository to set up the
development environment:

```bash
# 1. Create the virtual environment
python3 -m venv .venv

# 2. Activate the virtual environment
source .venv/bin/activate

# 3. Install the local development tools
pip install -r requirements-dev.txt
```

</details>

<details>

<summary><b>Running an Agent Locally</b></summary>

The following commands run an agent locally. You must specify the configuration
file name (without extension) and the service name in the format
`dir/file/service`. In these examples, we assume the file is `config/demo.yaml`
and the agent is `fulfillment-planning`.

### Agent in Web UI

```bash
python3 scripts/run_local.py config/demo/fulfillment-planning --web
```

Then choose agent "adk_a2a_agent" to chat with your agent. Please note your
agent will not be listed in the list of agents. You need to pick "adk_a2a_agent"
which is the name of the template used to generate the agent.

### Agent in a Docker container

To run the agent locally in a Docker container (the same that runs on Cloud
Run), execute:

```bash
python3 scripts/run_local.py config/demo/fulfillment-planning
```

</details>

<details>

<summary><b>Testing an Agent</b></summary>

To test, first run the agent in the Web UI (see command above), record the
scenarios you want to exercise, and then save the evaluation set file under the
`services/agents/adk_a2a_agent` directory using the name of the agent (replacing
dashes with underscores). For example, for the `fulfillment-planning` agent,
save the evaluation set under
`services/agents/adk_a2a_agent/fulfillment_planning.evalset.json`.

To execute the tests, run:

```bash
python3 scripts/run_local.py config/demo/fulfillment-planning --eval
```

</details>

<details>

<summary><b>Event Simulation</b></summary>

The `log-events` service includes a simulation mode that sends a predefined set
of events for testing purposes. To run the simulation locally using the Docker
container:

1.  Run the service using `run_local.py` and pass the `ENABLE_SIMULATION`
    environment variable using the `--env` flag:

    ```bash
    python3 scripts/run_local.py config/external/log-events --env ENABLE_SIMULATION=true
    ```

2.  Navigate to `http://127.0.0.1:8081` in your browser (note that
    `run_local.py` maps port 8080 in container to 8081 on host).

### Enabling Simulation on Cloud Run

If you want to enable the `log-events` simulation on the deployed Cloud Run
service, you need to set the `ENABLE_SIMULATION` environment variable to `true`
in the Cloud Run service configuration.

</details>

<details>

<summary><b>Calling the Agent</b></summary>

You can invoke endpoints on the agent by using `curl`.

To use the commands below, you need the URL of your deployed agent. For agents
deployed on Cloud Run, you can retrieve it and set it as an environment variable
with the following command (replace `fulfillment-planning` with your agent's
name if different):

```bash
export AGENT_URL=$(gcloud run services describe fulfillment-planning --region=$REGION --project=$PROJECT_ID --format='value(status.url)')
```

### Get the Agent Card

Retrieve the agent's card, which contains metadata and describes its
capabilities.

```bash
curl -s -X GET \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  "${AGENT_URL}/.well-known/agent-card.json"
```

### Send Message to the Agent

Send a direct message to the agent using the JSON-RPC protocol to simulate an
event or direct interaction.

```bash
curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
"${AGENT_URL}" \
  -H "Content-Type: application/json" \
  -H "original-event-id: 12345678-1234-1234-1234-123456789012" \
  -H "original-event-source: manual-testing" \
  -d '{
    "jsonrpc": "2.0",
    "id": "req-001",
    "method": "message/send",
    "params": {
      "message": {
        "messageId": "msg-001",
        "role": "user",
        "parts": [
          {
            "text": "Hi!"
          }
        ]
      },
      "configuration": {
        "blocking": false
      }
    }
  }' | jq
```

### Simulating Orders via Script

You can use the `publish_order.py` script to simulate order events directly
without using the Storefront UI.

The following sample command sends a large order. Specify the Message Bus full
resource name deployed to the Main Project:

```bash
python3 scripts/publish_order.py \
  --bus_name "<YOUR_BUS_NAME>" \
  --amount 15000 \
  --items "500x Enterprise Laptops" \
  --address "123 Main St, Toronto" \
  --env "demo" \
  --note "Standard corporate delivery."
```

</details>

# Troubleshooting

## Cold Starts and Transient Errors

During the initial deployment, you may see internal errors on
`google_eventarc_pipeline` creation. This is typically caused by "cold start"
issues in the Eventarc service. Retrying the deployment will likely resolve it.
