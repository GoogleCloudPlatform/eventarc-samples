# eventarc-agentic-workflows

This repository contains a sample project demonstrating how to deploy and manage
[**Eventarc**](https://docs.cloud.google.com/eventarc/docs)-driven agentic
workflows on Google Cloud Platform, as shown at
[Google Cloud Next 2026](https://www.googlecloudevents.com/next-vegas/).

![The log-events service showing the flow of events through the Eventarc
MessageBus.](log-events.png)

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

*   **Docker**: Follow the
    [official Docker installation instructions](https://docs.docker.com/get-docker/).
    A modern version of Docker supporting **Docker Buildx** is required.

*   **Python**: Ensure [Python 3.x](https://www.python.org/downloads/) is
    installed.

### Windows Compatibility

The deployment scripts and commands in this repository are written for Bash and
are designed for Linux/macOS. To run them on Windows, it is recommended to use
[**WSL (Windows Subsystem for Linux)**](https://learn.microsoft.com/en-us/windows/wsl/about).

## 2. Configuration

1.  Copy the example configuration file:

    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```

2.  Edit `terraform.tfvars` and replace the placeholders with your actual
    project IDs and bucket name:

    ```hcl
    workspace_projects = {
      demo     = "your-main-project-id"
      external = "your-external-project-id"
    }
    region   = "us-central1"
    bucket   = "your-tfstate-bucket"
    bus_name = "agentic-workflows"
    ```

The `bucket` above is a Cloud Storage bucket which is needed to hold the
Terraform state. The state is stored in a folder named `terraform/state`. Bucket
setup will follow in a later step (see
[Setup Remote State Bucket](#setup-remote-state-bucket)).

> [!NOTE]
>
> The selected `region` must be supported by Eventarc Advanced. See
> [Eventarc locations](https://docs.cloud.google.com/eventarc/docs/locations)
> for supported regions.

### Set Environment Variables

To make it easy to copy and paste the commands below, and to run an agent
locally (see [Local Development](#6-local-development--testing) section), you
must set relevant environment variables.

You can source the `prep_env.sh` script, which extracts the necessary
environment variables from `terraform.tfvars`:

```bash
source prep_env.sh
```

## 3. Project Setup (One-Time Execution)

This demo is deployed over 2 GCP projects. Before deploying infrastructure, you
need to create these projects and perform some one-time setup on each project.

### Project A (Main Project: `your-main-project-id`)

The principal deploying the configuration (e.g., your user account) needs
permissions to create and manage service accounts, grant IAM roles, enable APIs,
and create resources. Broadly, **Project Owner** or **Project Editor** combined
with **Project IAM Admin** is required to allow Terraform to:

-   Enable required APIs (Eventarc, Cloud Run, Vertex AI, Model Armor).
-   Create Service Accounts for agents and invokers.
-   Grant IAM permissions (e.g., Eventarc Message Bus User, Vertex AI User,
    Cloud Run Invoker).
-   Create the Eventarc Message Bus, Artifact Registry, and Cloud Run services.

### Project B (External Project: `your-main-project-id-ext`)

Similar to Project A, you will need permissions to create resources and manage
IAM in this project. **Project Owner** or **Project Editor** with **Project IAM
Admin** is required to allow Terraform to:

-   Create Service Accounts for external services.
-   Grant IAM permissions (e.g., Cloud Run Invoker).
-   Deploy Cloud Run services and Eventarc pipelines/enrollments targeting them.

### Setup Remote State Bucket

To share Terraform state across machines and prevent resource duplication
conflicts, create a Google Cloud Storage (GCS) bucket to house the state file.

```bash
gcloud storage buckets create gs://$TFSTATE_BUCKET --project=$PROJECT_ID --location=$REGION
```

### Docker Authentication

To pull and push images to Google Artifact Registry during deployment, configure
Docker to authorize with the Artifact Registry:

```bash
gcloud auth configure-docker $REGION-docker.pkg.dev --project=$PROJECT_ID
```

## 4. Deployment

For deployment we use Terraform to deploy all components in the Demo.

You can deploy the full demo stack using a single command:

```bash
./deploy.sh all
```

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

### Running the demo

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
3.  If your service needs access to shared tools or other directories outside
    its own folder during build, you can add a `docker-compose.yaml` file in the
    service directory to define additional build contexts.
4.  Update `demo.yaml` in the config directory to define the new service and
    point `src_dir` to your new directory (e.g., `services/my_custom_service`).

Example `docker-compose.yaml` (optional):

```yaml
services:
  agent:
    build:
      context: .
      dockerfile: Dockerfile
      additional_contexts:
        shared_tools: ../shared_tools
```

The build system will automatically use `docker buildx bake` if a
`docker-compose.yaml` file is present in the service's `src_dir`, or fall back
to `docker buildx build` if only a `Dockerfile` is present.

## Adding a New ADK Agent

To add a new ADK agent:

1.  Create a directory under `services/agents/` (or use
    `services/agents/adk_a2a_agent` as a template).
2.  Ensure it has a `Dockerfile` and optionally a `docker-compose.yaml` as
    described above.
3.  Update `demo.yaml` in the config directory to define the new service and
    point `src_dir` to your new directory (e.g.,
    `services/agents/my_new_agent`).

## Local Development & Testing

This section is required only if you want to run agents locally, use the Web UI,
or run evaluations.

### Local Development Setup

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

### Running an Agent Locally

The following commands run an agent locally. You must specify the configuration
file name (without extension) and the service name in the format
`dir/file/service`. In these examples, we assume the file is `config/demo.yaml`
and the agent is `fulfillment-planning`.

#### Agent in Web UI

```bash
python3 scripts/run_local.py config/demo/fulfillment-planning --web
```

Then choose agent "adk_a2a_agent" to chat with your agent. Please note your
agent will not be listed in the list of agents. You need to pick "adk_a2a_agent"
which is the name of the template used to generate the agent.

#### Agent in a Docker container:

To run the agent locally in a Docker container (the same that runs on Cloud
Run), execute:

```bash
python3 scripts/run_local.py config/demo/fulfillment-planning
```

### Testing an Agent

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

### Event Simulation

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

## Operations

### Calling the Agent

You can invoke endpoints on the agent by using `curl`.

To use the commands below, you need the URL of your deployed agent. You can
retrieve it and set it as an environment variable with the following command
(replace `fulfillment-planning` with your agent's name if different):

```bash
export AGENT_URL=$(gcloud run services describe fulfillment-planning --region=$REGION --project=$PROJECT_ID --format='value(status.url)')
```

#### Get the Agent Card

Retrieve the agent's card, which contains metadata and describes its
capabilities.

```bash
curl -s -X GET \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  "${AGENT_URL}/.well-known/agent-card.json"
```

#### Send Message to the Agent

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

#### Enabling Simulation on Cloud Run

If you want to enable the `log-events` simulation on the deployed Cloud Run
service, you need to set the `ENABLE_SIMULATION` environment variable to `true`
in the Cloud Run service configuration.

#### Simulating Orders via Script

You can use the `publish_order.py` script to simulate order events directly
without using the Storefront UI.

The following sample command sends a large order:

```bash
python3 scripts/publish_order.py \
  --bus_name "projects/$PROJECT_ID/locations/$REGION/messageBuses/$BUS_ID" \
  --amount 15000 \
  --items "500x Enterprise Laptops" \
  --address "123 Main St, Toronto" \
  --env "demo" \
  --note "Standard corporate delivery."
```

# Troubleshooting

## Cold Starts and Transient Errors

During the initial deployment, you may see internal errors on
`google_eventarc_pipeline` creation. This is typically caused by "cold start"
issues in the Eventarc service. Retrying the deployment will likely resolve it.
