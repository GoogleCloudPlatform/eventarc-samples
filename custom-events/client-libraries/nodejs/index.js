const { CloudEvent } = require('cloudevents');
const { PublisherClient } = require('@google-cloud/eventarc-publishing');

/**
 * Builds CloudEvent for sending to Eventarc Channel.
 * 
 * @param {Record<string, any>} payload object that will be added in the event.
 * @returns Fully constructed CloudEvent
 */
const BuildCloudEvent = (
    payload
 ) => {
   return new CloudEvent({
     type: "custom.type",
     source: "//event/from/nodejs",
     data: payload,
     datacontenttype: "application/json",
     time: new Date().toISOString(),
     extsourcelang: 'javascript'
     });
 }

/**
 * Invokes Eventarc Publisher client on specified channel with the event.
 * @param {string} channel 
 * @param {CloudEvent} event 
 */
const callPublishEvents = async (
    channel,
    event
) => {
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
    console.log("Costructed events for sending. ",request);

    // Run request
    try {
        const response = await publishingClient.publishEvents(request);
        console.log("Received response. ", response);
    } catch (e) {
        console.error("Received error from publishing API. ", e);
    }
}

const arguments = process.argv.slice(2);
const channel = arguments[0];
if (!channel) {
    console.error("Missing channel name, please pass it in the argument.")
    return;
}

const event = BuildCloudEvent({
    message1: "Data"
});

callPublishEvents(channel, event);
