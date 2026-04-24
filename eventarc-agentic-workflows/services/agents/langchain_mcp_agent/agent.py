import contextlib
import json
import logging
import os
from fastapi import FastAPI
from langchain_core.tools import tool
from langchain_google_vertexai import ChatVertexAI
from langgraph.prebuilt import create_react_agent
from mcp.server.fastmcp import FastMCP
from shared_tools.eventarc import publish_to_eventarc
from shared_tools.logging_middleware import RequestLoggingASGIMiddleware

logging.basicConfig(level=logging.INFO, format="%(message)s")

# 1. Fetch Configuration
BUS_RESOURCE_NAME = os.getenv("EVENTARC_BUS_NAME", "mock-bus-for-testing")
SERVICE_NAME = os.getenv("SERVICE_NAME", "generic-service")
AGENT_INSTRUCTION = os.getenv(
    "AGENT_INSTRUCTION", "You are a helpful assistant."
)

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
def _publish_event(type: str, data: dict, attributes: dict = None) -> str:
  logging.info(f"Emitting event: {type} with data: {data}")
  return publish_to_eventarc(
      bus=BUS_RESOURCE_NAME,
      type=type,
      source=SERVICE_NAME,
      data=json.dumps(data) if isinstance(data, dict) else data,
      datacontenttype="application/json",
      custom_attributes=attributes,
  )


@tool
def emit_business_event(type: str, data: dict, attributes: dict = None) -> str:
  """Publishes an event back to the Eventarc message bus.

  Args:
      type: The type of the CloudEvent (e.g., 'fulfillment.plan.created').
      data: The main JSON payload of the event.
      attributes: Optional dictionary of custom string key-value pairs to be
        included as custom attributes of the CloudEvent.
  """
  return _publish_event(type, data, attributes)


# 3. Initialize LangChain Agent using Vertex AI
llm = ChatVertexAI(
    model_name="gemini-2.5-flash",
    model_kwargs={"system_instruction": full_instruction},
)
tools = [emit_business_event]
agent_executor = create_react_agent(llm, tools)

# 4. FastMCP Server Implementation
# Explicitly set host="0.0.0.0" to allow Cloud Run to route traffic to this container.
# This relaxes the default localhost-only host header validation used for local development.
mcp = FastMCP(
    "LangChain Agent Server",
    json_response=True,
    stateless_http=True,
    streamable_http_path="/",
    host="0.0.0.0",
)


@mcp.tool()
def run_agent(prompt: str) -> str:
  """Run the agent with a prompt.

  Args:
      prompt: The prompt for the agent to act upon.
  """
  logging.info(f"Received run_agent call with prompt: {prompt}")
  try:
    result = agent_executor.invoke(
        {"messages": [("system", full_instruction), ("user", prompt)]}
    )
    return result["messages"][-1].content
  except Exception as e:
    logging.error(f"Error running agent: {str(e)}")
    try:
      res = _publish_event(
          type="error.agent", data={"error": str(e), "prompt": prompt}
      )
      logging.info(f"Published error event: {res}")
    except Exception as pe:
      logging.error(f"Failed to publish error event: {str(pe)}")
    return f"Error running agent: {str(e)}"


# 5. FastAPI App and Lifespan
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
