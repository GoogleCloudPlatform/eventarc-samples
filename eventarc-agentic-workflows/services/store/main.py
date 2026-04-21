import json
import logging
import os
import uuid
from fastapi import FastAPI, Form, HTTPException, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from shared_tools.eventarc import publish_to_eventarc

logging.basicConfig(level=logging.INFO, format="%(message)s")

BUS_RESOURCE_NAME = os.getenv("EVENTARC_BUS_NAME", "mock-bus-for-testing")
SERVICE_NAME = os.getenv("SERVICE_NAME", "store")

app = FastAPI()

URL_PREFIX = os.getenv("URL_PREFIX", "/store")

# Mount static files
app.mount(
    "/static", StaticFiles(directory="services/store/static"), name="static"
)
if URL_PREFIX and URL_PREFIX != "/":
  app.mount(
      f"{URL_PREFIX}/static",
      StaticFiles(directory="services/store/static"),
      name="static_prefixed",
  )

# Templates
templates = Jinja2Templates(directory="services/store/templates")
templates.env.cache = None


@app.get("/")
@app.get(URL_PREFIX)
@app.get(f"{URL_PREFIX}/")
async def welcome(request: Request):
  return templates.TemplateResponse(request, "index.html", {"request": request})


@app.get("/checkout")
@app.get(f"{URL_PREFIX}/checkout")
async def checkout(request: Request):
  # Prefilled values
  product = "Stiletto Pump"
  color = "Scarlet Red"
  size = "8"  # Common size
  quantity = 515
  address = "123 Main St, Toronto"

  return templates.TemplateResponse(
      request,
      "checkout.html",
      {
          "request": request,
          "product": product,
          "color": color,
          "size": size,
          "quantity": quantity,
          "address": address,
      },
  )


@app.post("/create-order")
@app.post(f"{URL_PREFIX}/create-order")
async def create_order(
    request: Request,
    user_note: str = Form(""),
    product: str = Form(""),
    quantity: int = Form(0),
    address: str = Form(""),
    color: str = Form(""),
    size: str = Form(""),
):
  # Generate random order ID
  order_id = "ORD-" + str(uuid.uuid4())[:6].upper()

  # Construct the event data
  event_data = {
      "order_id": order_id,
      "shipping_address": address,
      "user_note": user_note,
      "items": [{
          "item_name": f"{product} ({color}, Size {size})",
          "quantity": quantity,
      }],
  }

  logging.info(f"Creating order: {event_data}")

  # Publish to Eventarc
  result = publish_to_eventarc(
      bus=BUS_RESOURCE_NAME,
      type="order.created",
      source=SERVICE_NAME,
      data=event_data,
      datacontenttype="application/json",
  )

  logging.info(f"Publish result: {result}")

  if "Error" in result:
    raise HTTPException(status_code=500, detail=result)

  return templates.TemplateResponse(
      request,
      "success.html",
      {"request": request, "order_id": order_id, "result": result},
  )
