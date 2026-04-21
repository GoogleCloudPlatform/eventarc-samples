import logging
import os
from fastapi import FastAPI, Request
from shared_tools.logging_middleware import RequestLoggingASGIMiddleware

logging.basicConfig(level=logging.INFO, format="%(message)s")

BUS_RESOURCE_NAME = os.getenv("EVENTARC_BUS_NAME", "mock-bus-for-testing")
SERVICE_NAME = os.getenv("SERVICE_NAME", "third-party-shipment")

app = FastAPI()

# Add the middleware
app.add_middleware(
    RequestLoggingASGIMiddleware,
    bus_name=BUS_RESOURCE_NAME,
    service_name=SERVICE_NAME,
)


@app.post("/")
async def place_shipment(request: Request):
  data = await request.json()
  logging.info(f"Received shipment request: {data}")

  carrier_request = data.get("carrier_request", {})
  order_id = carrier_request.get("reference_id")
  consignment = carrier_request.get("consignment", {})
  parcels = consignment.get("parcels", [])
  address = consignment.get("address")

  logging.info(f"Shipping address: {address}")

  return {
      "status": "success",
      "message": f"Shipment requested for order {order_id}",
      "processed_items_count": len(parcels),
  }
