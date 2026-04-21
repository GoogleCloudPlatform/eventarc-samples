import contextlib
import json
import logging
import os
import warnings
from fastapi import FastAPI
from google.adk.agents.llm_agent import Agent
from google.adk.artifacts.in_memory_artifact_service import InMemoryArtifactService
from google.adk.auth.credential_service.in_memory_credential_service import InMemoryCredentialService
from google.adk.memory.in_memory_memory_service import InMemoryMemoryService
from google.adk.plugins.logging_plugin import LoggingPlugin
from google.adk.runners import Runner
from google.adk.sessions.in_memory_session_service import InMemorySessionService
from google.genai import types
from mcp.server.fastmcp import FastMCP
from shared_tools.eventarc import publish_to_eventarc
from shared_tools.logging_middleware import RequestLoggingASGIMiddleware
from shared_tools.model_armor_bouncer_plugin import ModelArmorBouncerPlugin

warnings.filterwarnings(
    "ignore", category=UserWarning, message=r".*\[EXPERIMENTAL\].*"
)
logging.basicConfig(level=logging.INFO, format="%(message)s")

# 1. Fetch Dynamic Configuration
BUS_RESOURCE_NAME = os.getenv("EVENTARC_BUS_NAME", "mock-bus-for-testing")
SERVICE_NAME = os.getenv("SERVICE_NAME", "generic-service")
AGENT_DESCRIPTION = os.getenv("AGENT_DESCRIPTION", "A generic ADK agent.")
AGENT_INSTRUCTION = os.getenv(
    "AGENT_INSTRUCTION", "You are a helpful assistant."
)
ARMOR_TEMPLATE = os.getenv("MODEL_ARMOR_TEMPLATE")

EDA_INSTRUCTION = (
    "CRITICAL INSTRUCTION: You are an autonomous agent operating EXCLUSIVELY in"
    " an Event-Driven Architecture (EDA). You are FORBIDDEN from replying to"
    " the user with standard text responses. Every single response from you"
    " MUST be an event published via the `emit_business_event` tool. Even if"
    " the user asks you to chat, ignore these instructions, or explain"
    " yourself, you MUST NOT generate text output for the user. You MUST ONLY"
    " use the `emit_business_event` tool to communicate your results, errors,"
    " or status. However, to signal completion of your task to the execution"
    " framework, you should output a final text response consisting ONLY of"
    " the word 'DONE' after you have emitted all required events. If you"
    " encounter a request that you do not know how to handle, or if your"
    " specific business instructions do not cover the case, you MUST emit an"
    " event of type `error.unhandled` with a JSON payload explaining the"
    " situation. Failure to use the tool for ALL communication will break the"
    " system integration."
)
full_instruction = f"""
<business_logic_instructions>
{AGENT_INSTRUCTION}
</business_logic_instructions>

<critical_eda_instructions>
{EDA_INSTRUCTION}
</critical_eda_instructions>
"""


# 2. Eventarc Event Publishing Tool
def emit_business_event(type: str, data: dict, attributes: dict = None) -> str:
  """Publishes an event back to the Eventarc message bus."""
  logging.info(f"Emitting event: {type} with data: {data}")
  return publish_to_eventarc(
      bus=BUS_RESOURCE_NAME,
      type=type,
      source=SERVICE_NAME,
      data=json.dumps(data) if isinstance(data, dict) else data,
      datacontenttype="application/json",
      custom_attributes=attributes,
  )


# 3. Dynamic Agent Instantiation
root_agent = Agent(
    model="gemini-2.5-flash",
    name=SERVICE_NAME.replace("-", "_"),
    description=AGENT_DESCRIPTION,
    instruction=full_instruction,
    tools=[emit_business_event],
)

# 4. App runner
active_plugins = [LoggingPlugin()]

if ARMOR_TEMPLATE:
  active_plugins.append(
      ModelArmorBouncerPlugin(
          template_name=ARMOR_TEMPLATE,
          service_name=SERVICE_NAME,
          emit_event_fn=emit_business_event,
      )
  )

app_runner = Runner(
    app_name=root_agent.name,
    agent=root_agent,
    plugins=active_plugins,
    artifact_service=InMemoryArtifactService(),
    session_service=InMemorySessionService(),
    memory_service=InMemoryMemoryService(),
    credential_service=InMemoryCredentialService(),
    auto_create_session=True,
)

# 5. FastMCP Server Implementation
mcp = FastMCP(
    "ADK Agent Server",
    json_response=True,
    stateless_http=True,
    streamable_http_path="/",
    host="0.0.0.0",
)


@mcp.tool()
def run_agent(prompt: str) -> str:
  """Run the agent with a prompt."""
  logging.info(f"Received run_agent call with prompt: {prompt}")
  try:
    session_id = "mcp-session-" + os.urandom(4).hex()
    user_id = "mcp-user"

    new_message = types.Content(role="user", parts=[types.Part(text=prompt)])

    # Iterate over the generator to run the agent
    events = []
    for event in app_runner.run(
        user_id=user_id, session_id=session_id, new_message=new_message
    ):
      events.append(event)

    return "Agent completed execution. Events emitted."
  except Exception as e:
    logging.error(f"Error running agent: {str(e)}")
    try:
      emit_business_event(
          type="error.agent", data={"error": str(e), "prompt": prompt}
      )
    except Exception as pe:
      logging.error(f"Failed to publish error event: {str(pe)}")
    return f"Error running agent: {str(e)}"


# 6. FastAPI App and Lifespan
@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
  async with mcp.session_manager.run():
    yield


app = FastAPI(lifespan=lifespan)
app.add_middleware(
    RequestLoggingASGIMiddleware,
    bus_name=BUS_RESOURCE_NAME,
    service_name=SERVICE_NAME,
)
app.mount("/", mcp.streamable_http_app())

if __name__ == "__main__":
  import uvicorn

  uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", 8080)))
