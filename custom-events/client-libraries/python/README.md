# Publisher sample - Python

Make sure [Proto Buffer Compile](https://grpc.io/docs/protoc-installation/) is
installed.

For example, on MacOS:

```sh
brew install protobuf
```

Build with make:

```sh
make
```

Example invocation:

```sh
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
CHANNEL_NAME=hello-custom-events-channel

python3 publish.py \
    --channel projects/$PROJECT_ID/locations/$REGION/channels/$CHANNEL_NAME \
    --event_source "//from/python" \
    --event_id 12345 \
    --event_type mycompany.myorg.myproject.v1.myevent \
    --event_data '{"message": "Hello world from python"}' \
    --log=DEBUG
```
