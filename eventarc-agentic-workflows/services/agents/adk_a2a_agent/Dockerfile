# Use the official lightweight Python image
FROM python:3.12-slim

# Set up the runtime environment
ENV PORT=8080
ENV GOOGLE_GENAI_USE_VERTEXAI=1
ENV STARTUP_MODE="a2a"

# Set the working directory
WORKDIR /app

# Cache the dependency layer
COPY services/agents/adk_a2a_agent/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir uvicorn -r /app/requirements.txt

# Copy shared_tools
COPY services/shared_tools /app/shared_tools/

# Copy the agent code
COPY services/agents/adk_a2a_agent /app/agents/adk_a2a_agent

# Tell Python to look in /app
ENV PYTHONPATH=/app

# Start the server
WORKDIR /app
CMD ["sh", "-c", "if [ \"$STARTUP_MODE\" = 'ui' ]; then adk web agents --host 0.0.0.0 --port ${PORT} --a2a ${URL_PREFIX:+--url_prefix $URL_PREFIX}; else uvicorn agents.adk_a2a_agent.agent:a2a_app --host 0.0.0.0 --port ${PORT}; fi"]
