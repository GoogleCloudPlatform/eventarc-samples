# Use the official lightweight Python image
FROM python:3.12-slim

# Set up the runtime environment
ENV PORT=8080

# Set the working directory
WORKDIR /app

# Cache the dependency layer
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy shared_tools from additional context
COPY --from=shared_tools . /app/shared_tools/

# Copy the service code
WORKDIR /app/services/third_party_shipment
COPY . .

# Tell Python to look in /app
ENV PYTHONPATH=/app

# Start the server
WORKDIR /app
CMD ["sh", "-c", "uvicorn services.third_party_shipment.main:app --host 0.0.0.0 --port ${PORT}"]
