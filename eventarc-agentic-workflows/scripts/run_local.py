import argparse
import os
import subprocess
from dotenv import dotenv_values
import yaml


def main():
  parser = argparse.ArgumentParser(
      description="Run, Evaluate, or Debug an ADK agent locally."
  )
  parser.add_argument(
      "agent_name", help="The name of the agent (key from demo.yaml)"
  )
  parser.add_argument(
      "--eval", action="store_true", help="Run automated ADK evaluations"
  )
  parser.add_argument(
      "--web",
      action="store_true",
      help="Launch the ADK Web UI for visual debugging",
  )
  parser.add_argument(
      "--env", action="append", help="Set environment variables (KEY=VALUE)"
  )
  args = parser.parse_args()

  # 1. Load Configuration
  agent_arg = args.agent_name
  if "/" not in agent_arg:
    print(
        "❌ Error: You must specify the config file and service name in the"
        " format 'file/service'."
    )
    print("Example: python run_local.py demo/fulfillment-planning")
    return

  file_ref, agent_name = agent_arg.rsplit("/", 1)

  yaml_file = file_ref
  if "." not in file_ref:
    if os.path.exists(file_ref + ".yaml"):
      yaml_file = file_ref + ".yaml"

  try:
    with open(yaml_file, "r") as f:
      agents_config = yaml.safe_load(f).get("services", {})
  except FileNotFoundError:
    print(f"❌ Error: {yaml_file} not found.")
    return

  if agent_name not in agents_config:
    print(f"❌ Error: Service '{agent_name}' not found in {yaml_file}.")
    return

  config = agents_config[agent_name]

  # 2. Setup Environment Variables
  env_vars = os.environ.copy()
  env_vars["SERVICE_NAME"] = agent_name
  env_vars["PYTHONPATH"] = (
      os.path.abspath(".") + ":" + os.path.abspath("services")
  )

  # --- VERTEX AI CONFIGURATION ---
  print("🔄 Configuring Vertex AI...")
  env_vars["GOOGLE_GENAI_USE_VERTEXAI"] = "1"

  # Disable mutual TLS (mTLS) for local testing to prevent certificate provider errors
  env_vars["GOOGLE_API_USE_CLIENT_CERTIFICATE"] = "false"
  env_vars["GOOGLE_API_USE_MTLS_ENDPOINT"] = "never"

  if "PROJECT_ID" not in env_vars or "REGION" not in env_vars:
    print(
        "❌ Error: PROJECT_ID, REGION, and BUS_ID environment variables are"
        " required."
    )
    return

  project_id = env_vars["PROJECT_ID"]
  region = env_vars["REGION"]
  env_vars["GOOGLE_CLOUD_PROJECT"] = project_id
  env_vars["GOOGLE_CLOUD_REGION"] = region

  if "EVENTARC_BUS_NAME" not in env_vars:
    if "BUS_ID" not in env_vars:
      print(
          "❌ Error: EVENTARC_BUS_NAME or BUS_ID environment variables are"
          " required."
      )
      return
    env_vars["EVENTARC_BUS_NAME"] = (
        f"projects/{project_id}/locations/{region}/messageBuses/{env_vars['BUS_ID']}"
    )

  env_vars["ADK_SUPPRESS_EXPERIMENTAL_FEATURE_WARNINGS"] = "true"

  # If model_armor exists, build the template resource string
  if "model_armor" in config:
    template_name = (
        f"projects/{project_id}/locations/{region}/templates/{agent_name}-armor"
    )
    env_vars["MODEL_ARMOR_TEMPLATE"] = template_name
    print(f"🛡️  Model Armor enabled using template: {template_name}")

  custom_envs = config.get("env_vars", {})
  for key, value in custom_envs.items():
    env_vars[key] = str(value)
  # ------------------------------------

  # 3. Execution Routing
  if args.web:
    print(f"🌐 Starting ADK Web UI for {agent_name}...")
    env_vars["ADK_LOCAL_WEB"] = "true"
    subprocess.run(["adk", "web", "services/agents"], env=env_vars)

  elif args.eval:
    print(f"🧪 Running automated ADK Evaluations for {agent_name}...")
    expected_eval_name = f"{agent_name.replace('-', '_')}.evalset.json"
    eval_file_path = f"{config['src_dir']}/{expected_eval_name}"

    if not os.path.exists(eval_file_path):
      print(
          f"❌ Error: Could not find '{expected_eval_name}' in"
          f" {config['src_dir']}."
      )
      print(
          "Please run with --web first and save an Evaluation Set named"
          f" '{expected_eval_name.replace('.evalset.json', '')}'."
      )
      return

    print(f"📂 Found dedicated evaluation set: {eval_file_path}")

    eval_cmd = [
        "adk",
        "eval",
        config["src_dir"],
        eval_file_path,
        "--config_file_path=evaluations/test_config.json",
        "--print_detailed_results",
    ]
    subprocess.run(eval_cmd, env=env_vars)

  else:
    print(f"🔨 Building Docker image for {agent_name}...")
    if os.path.exists(os.path.join(config["src_dir"], "docker-compose.yaml")):
      build_cmd = (
          "BUILDX_BAKE_ENTITLEMENTS_FS=0 docker buildx bake --set"
          f" *.tags=local-{agent_name}"
      )
    else:
      build_cmd = f"docker buildx build -t local-{agent_name} ."
    subprocess.run(build_cmd, shell=True, check=True, cwd=config["src_dir"])

    print(f"🚀 Starting {agent_name} locally on port 8081...")
    print("👉 Listening for requests on: http://localhost:8081")

    # Dynamically fetch the local gcloud config directory
    try:
      gcloud_dir = subprocess.check_output(
          ["gcloud", "info", "--format=value(config.paths.global_config_dir)"],
          text=True,
      ).strip()
    except subprocess.CalledProcessError:
      print(
          "⚠️ Warning: Could not locate gcloud config directory. Eventarc"
          " publishing may fail."
      )
      gcloud_dir = ""

    run_cmd = [
        "docker",
        "run",
        "--rm",
        "-p",
        "8081:8080",
        "-it",
        "-e",
        f"SERVICE_NAME={agent_name}",
        # Pass the Vertex variables to Docker
        "-e",
        f"ADK_SUPPRESS_EXPERIMENTAL_FEATURE_WARNINGS={env_vars['ADK_SUPPRESS_EXPERIMENTAL_FEATURE_WARNINGS']}",
        "-e",
        f"EVENTARC_BUS_NAME={env_vars['EVENTARC_BUS_NAME']}",
        "-e",
        f"GOOGLE_GENAI_USE_VERTEXAI={env_vars['GOOGLE_GENAI_USE_VERTEXAI']}",
        "-e",
        f"GOOGLE_CLOUD_PROJECT={env_vars['GOOGLE_CLOUD_PROJECT']}",
        "-e",
        f"GOOGLE_CLOUD_REGION={env_vars['GOOGLE_CLOUD_REGION']}",
    ]

    if gcloud_dir:
      run_cmd.extend([
          "-v",
          f"{gcloud_dir}:/gcp:ro",
          "-e",
          "GOOGLE_APPLICATION_CREDENTIALS=/gcp/application_default_credentials.json",
      ])

    if "model_armor" in config:
      run_cmd.extend(
          ["-e", f"MODEL_ARMOR_TEMPLATE={env_vars['MODEL_ARMOR_TEMPLATE']}"]
      )

    custom_envs = config.get("env_vars", {})
    for key, value in custom_envs.items():
      run_cmd.extend(["-e", f"{key}={value}"])

    if args.env:
      for env_str in args.env:
        run_cmd.extend(["-e", env_str])

    run_cmd.append(f"local-{agent_name}")
    subprocess.run(run_cmd)


if __name__ == "__main__":
  main()
