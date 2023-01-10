const { CloudEvent } = require('cloudevents');
const { PublisherClient } = require('@google-cloud/eventarc-publishing');

/**
 * Builds a CloudEvent to publish to an Eventarc channel.
 *
 * @returns Fully constructed CloudEvent
 */
const BuildCloudEvent = () => {
   return new CloudEvent({
     type: "provider.v1.event",
     source: "//provider/source",
     data: {
        message: "Hello World from Node.js"
     },
     datacontenttype: "application/json",
     time: new Date().toISOString(),
     // Note: someattribute and somevalue have to match with the client trigger!
     someattribute: 'somevalue'
     });
 }

/**
 * Publish event to the channel connection with the Eventarc publisher client.
 *
 * @param {string} channel
 * @param {CloudEvent} event
 */
const publishEventToChannelConnection = async (channelConnection, event) => {
    // Instantiates a client with default credentials and options.
    const publishingClient = new PublisherClient();

    // Construct publish request.
    const request = {
        channelConnection: channelConnection,
        // Prepare text event rather than proto representation.
        // Since NodeJS CloudEvents SDK doesn't have method to transform
        // the object to protobuf it's easier to send the text representation.
        textEvents: [
            JSON.stringify(event)
        ]
    };
    console.log("Constructed the request with the event: ", request);

    // Publish event
    try {
        const response = await publishingClient.publishChannelConnectionEvents(request);
        console.log("Received response: ", response);
    } catch (e) {
        console.error("Received error from publishing API: ", e);
    }
}

const arguments = process.argv.slice(2);
const channelConnection = arguments[0];
if (!channelConnection) {
    console.error("Missing channel connection, please pass it in the argument in the form of projects/$PROJECT_ID/locations/$REGION/channels/$CHANNEL_CONNECTION_ID")
    return;
}

const event = BuildCloudEvent();

publishEventToChannelConnection(channelConnection, event);
