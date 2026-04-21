import logging
from google.adk.plugins import BasePlugin
from google.api_core.client_options import ClientOptions
from google.cloud import modelarmor_v1


class ModelArmorBouncerPlugin(BasePlugin):

  def __init__(self, template_name: str, service_name: str, emit_event_fn):
    super().__init__(name="model_armor_bouncer")
    self.template_name = template_name
    self.service_name = service_name
    self.emit_event_fn = emit_event_fn

    if not self.template_name:
      logging.error("❌ MODEL_ARMOR_TEMPLATE environment variable not set.")
      self.client = None
      return

    try:
      parts = self.template_name.split("/")
      if len(parts) < 4 or parts[2] != "locations":
        raise ValueError(f"Invalid template name format: {self.template_name}")
      location = parts[3]
    except Exception as e:
      logging.error(
          "❌ Failed to parse location from template name:"
          f" {self.template_name}. Error: {e}"
      )
      self.client = None
      return

    api_endpoint = f"modelarmor.{location}.rep.googleapis.com"
    try:
      client_options = ClientOptions(api_endpoint=api_endpoint)
      self.client = modelarmor_v1.ModelArmorClient(
          client_options=client_options
      )
      logging.info(
          "🛡️ Model Armor Bouncer initialized with template:"
          f" {self.template_name} using endpoint: {api_endpoint}"
      )
    except Exception as e:
      logging.error(f"❌ Failed to create Model Armor client: {e}")
      self.client = None

  async def before_model_callback(self, **kwargs):
    if not self.client:
      logging.warning("⚠️ Model Armor client not initialized, skipping check.")
      return

    llm_request = kwargs.get("llm_request")

    if not llm_request or not getattr(llm_request, "contents", None):
      logging.warning(
          "⚠️ RequestLoggingPlugin: No llm_request or contents found."
      )
      return

    try:
      latest_content = llm_request.contents[-1]

      if hasattr(latest_content, "parts") and latest_content.parts:
        prompt_text = " ".join(
            [p.text for p in latest_content.parts if getattr(p, "text", None)]
        )
      elif isinstance(latest_content, dict) and "parts" in latest_content:
        prompt_text = " ".join([
            p.get("text", "") for p in latest_content["parts"] if p.get("text")
        ])
      else:
        prompt_text = str(latest_content)

      if not prompt_text.strip():
        return
    except Exception as e:
      logging.error(f"Failed to extract prompt text for Model Armor: {e}")
      return

    request = modelarmor_v1.SanitizeUserPromptRequest(
        name=self.template_name,
        user_prompt_data=modelarmor_v1.DataItem(text=prompt_text),
    )

    try:
      response = self.client.sanitize_user_prompt(request=request)
      result = response.sanitization_result

      if (
          result.filter_match_state
          == modelarmor_v1.FilterMatchState.MATCH_FOUND
      ):
        logging.warning(
            "⚠️ Prompt was flagged by Model Armor! Emitting error event and"
            " blocking request."
        )

        error_payload = {
            "error_message": (
                "Prompt blocked by enterprise security policies (Model Armor)."
            ),
            "service": self.service_name,
            "blocked_content_snippet": (
                prompt_text[:200] + "..."
                if len(prompt_text) > 200
                else prompt_text
            ),
        }

        self.emit_event_fn(type="error.model-armor", data=error_payload)

        raise ValueError("Request blocked by enterprise security policies.")
      else:
        logging.info("✅ Prompt passed Model Armor inspection.")

    except Exception as e:
      if "blocked by enterprise security policies" not in str(e):
        logging.error(f"❌ Model Armor API failure: {e}")
      raise
