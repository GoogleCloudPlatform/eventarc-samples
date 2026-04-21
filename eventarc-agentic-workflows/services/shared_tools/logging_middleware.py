import json
import logging
from .eventarc import publish_to_eventarc

# Headers to strip from logged requests (exact match, case-insensitive)
EXACT_HEADERS_TO_STRIP = {
    "authorization",
    "traceparent",
    "forwarded",
}

# Header prefixes to strip from logged requests (case-insensitive)
PREFIX_HEADERS_TO_STRIP = {
    "x-",
}


class RequestLoggingASGIMiddleware:
  """ASGI Middleware.

  Intercepts incoming HTTP requests, extracts metadata, and logs the raw request
  to Eventarc before passing it to the application.
  """

  def __init__(self, app, bus_name: str, service_name: str):
    self.app = app
    self.bus_name = bus_name
    self.service_name = service_name

  async def __call__(self, scope, receive, send):
    if scope["type"] != "http":
      await self.app(scope, receive, send)
      return

    # 1. Capture Headers
    headers = {}
    for k, v in scope.get("headers", []):
      try:
        headers[k.decode("utf-8").lower()] = v.decode("utf-8")
      except Exception:
        continue
    original_event_id = headers.get("ce-id") or headers.get(
        "original-event-id", "unknown-id"
    )
    original_event_source = headers.get("ce-source") or headers.get(
        "original-event-source", "unknown-source"
    )

    # 2. Capture Body without consuming it for the app
    body_chunks = []
    more_body = True
    messages = []

    while more_body:
      message = await receive()
      messages.append(message)
      if message["type"] == "http.request":
        body_chunks.append(message.get("body", b""))
        more_body = message.get("more_body", False)

    full_body = b"".join(body_chunks)

    # 3. Format raw_request
    path = scope.get("path", "")
    method = scope.get("method", "")
    filtered_headers = {
        k: v
        for k, v in headers.items()
        if not any(k.startswith(prefix) for prefix in PREFIX_HEADERS_TO_STRIP)
        and k not in EXACT_HEADERS_TO_STRIP
    }
    headers_str = "\n".join([f"{k}: {v}" for k, v in filtered_headers.items()])

    try:
      body_str = full_body.decode("utf-8")
      if body_str.strip().startswith(("{", "[")):
        try:
          parsed_json = json.loads(body_str)
          body_str = json.dumps(parsed_json, indent=2)
        except Exception:
          pass  # Catch-all to ensure logging never crashes the request
    except UnicodeDecodeError:
      body_str = str(full_body)

    raw_request = f"{method} {path} HTTP/1.1\n{headers_str}\n\n{body_str}"

    # 4. Emit Eventarc Event
    logging.info(
        "📝 RequestLoggingASGIMiddleware: Emitting log.request.received for"
        f" {self.service_name}"
    )

    log_payload = {
        "original_event_id": original_event_id,
        "original_event_source": original_event_source,
        "raw_request": raw_request,
    }

    # Use the shared Eventarc publisher
    publish_to_eventarc(
        bus=self.bus_name,
        type="log.request.received",
        source=self.service_name,
        data=log_payload,
        datacontenttype="application/json",
    )

    # 5. Replay messages to the application
    async def replayed_receive():
      if messages:
        return messages.pop(0)
      return await receive()

    await self.app(scope, replayed_receive, send)


class AgentErrorHandlingMiddleware:
  """Middleware to catch exceptions and publish error events to Eventarc."""

  def __init__(self, app, bus_name: str, service_name: str):
    self.app = app
    self.bus_name = bus_name
    self.service_name = service_name

  async def __call__(self, scope, receive, send):
    if scope["type"] != "http":
      await self.app(scope, receive, send)
      return

    try:
      await self.app(scope, receive, send)
    except Exception as e:
      logging.error(f"❌ Agent error in {self.service_name}: {e}")
      try:
        publish_to_eventarc(
            bus=self.bus_name,
            type="error.request",
            source=self.service_name,
            data={"error": str(e)},
            datacontenttype="application/json",
        )
      except Exception as pe:
        logging.error(f"❌ Failed to publish error event: {pe}")
      raise e
