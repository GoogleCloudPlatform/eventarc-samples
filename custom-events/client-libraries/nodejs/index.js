const { CloudEvent } = require('cloudevents');
const { PublisherClient } = require('@google-cloud/eventarc-publishing');

/**
 * Builds a CloudEvent to publish to an Eventarc channel.
 *
 * @returns Fully constructed CloudEvent
 */
const BuildCloudEvent = () => {
   return new CloudEvent({
     type: "mycompany.myorg.myproject.v1.myevent",
     source: "//event/from/nodejs",
     data: {
        message: "Hello World from Node.js"
     },
     datacontenttype: "application/json",
     time: new Date().toISOString(),
     // Note: someattribute and somevalue have to match with the trigger!
     someattribute: 'somevalue'
     });
 }

/**
 * Publish event to the channel with the Eventarc publisher client.
 *
 * @param {string} channel
 * @param {CloudEvent} event
 */
const publishEventToChannel = async (channel, event) => {
    // Instantiates a client with default credentials and options.
    const publishingClient = new PublisherClient();

    // Construct publish request.
    const request = {
        channel: channel,
        // Prepare text event reather than proto representation.
        // Since NodeJS CloudEvents SDK doesn't have method to transform
        // the object to protobuf it's easier to send the text representation.
        textEvents: [
            JSON.stringify(event)
        ]
    };
    console.log("Constructed the request with the event: ", request);

    // Publish event
    try {
        const response = await publishingClient.publishEvents(request);
        console.log("Received response: ", response);
    } catch (e) {
        console.error("Received error from publishing API: ", e);
    }
}

const arguments = process.argv.slice(2);
const channel = arguments[0];
if (!channel) {
    console.error("Missing channel, please pass it in the argument in the form of projects/$PROJECT_ID/locations/$REGION/channels/$CHANNEL_NAME")
    return;
}

const event = BuildCloudEvent();

publishEventToChannel(channel, event);
