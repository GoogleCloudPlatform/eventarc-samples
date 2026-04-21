# Use the official lightweight Python image
FROM python:3.11-slim

# Set up the runtime environment
ENV PORT=8080
ENV GOOGLE_GENAI_USE_VERTEXAI=1
ENV STARTUP_MODE="a2a"

# Set the working directory
WORKDIR /app

# Cache the dependency layer
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir uvicorn -r /app/requirements.txt

# Copy shared_tools from additional context
COPY --from=shared_tools . /app/shared_tools/

# Copy the agent code to /app/agents/adk_a2a_agent
WORKDIR /app/agents/adk_a2a_agent
COPY . .

# Tell Python to look in /app
ENV PYTHONPATH=/app

# Start the server
WORKDIR /app
CMD ["sh", "-c", "if [ \"$STARTUP_MODE\" = 'ui' ]; then adk web agents --host 0.0.0.0 --port ${PORT} --a2a ${URL_PREFIX:+--url_prefix $URL_PREFIX}; else uvicorn agents.adk_a2a_agent.agent:a2a_app --host 0.0.0.0 --port ${PORT}; fi"]
