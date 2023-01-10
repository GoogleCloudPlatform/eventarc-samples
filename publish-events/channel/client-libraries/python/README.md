# Publisher sample - Python

This is a sample on how to use Eventarc publisher library with
CloudEvents SDK to publish an event to a custom channel using Python.

Install dependencies:

```sh
pip3 install -r requirements.txt
```

Publish:

```sh
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_NAME=hello-custom-events-channel

python3 publish.py \
    --channel projects/$PROJECT_ID/locations/$REGION/channels/$CHANNEL_NAME \
    --log=DEBUG
```
