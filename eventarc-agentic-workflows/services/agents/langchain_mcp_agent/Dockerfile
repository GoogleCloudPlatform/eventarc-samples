# Use the official lightweight Python image
FROM python:3.12-slim

# Set up the runtime environment
ENV PORT=8080
ENV GOOGLE_GENAI_USE_VERTEXAI=1

# Set the working directory
WORKDIR /app

# Cache the dependency layer
COPY services/agents/langchain_mcp_agent/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy shared_tools
COPY services/shared_tools /app/shared_tools/

# Copy the agent code
COPY services/agents/langchain_mcp_agent /app/agents/langchain_mcp_agent

# Tell Python to look in /app
ENV PYTHONPATH=/app

# Start the server
WORKDIR /app
CMD ["sh", "-c", "uvicorn agents.langchain_mcp_agent.agent:app --host 0.0.0.0 --port ${PORT}"]
