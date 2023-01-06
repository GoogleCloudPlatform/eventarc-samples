# Third party publisher sample - Python

This is a sample on how to use Eventarc publisher library with
CloudEvents SDK to publish an event to a provider channel connection using Python.

Install dependencies:

```sh
pip3 install -r requirements.txt
```

Publish:

```sh
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_CONNECTION_ID=hello-channel-connection

python3 publish.py \
    --channel projects/$PROJECT_ID/locations/$REGION/channelConnections/$CHANNEL_CONNECTION_ID \
    --log=DEBUG
```
