using Google.Cloud.Eventarc.Publishing.V1;
using Google.Protobuf.WellKnownTypes;
using Io.Cloudevents.V1;
using static Io.Cloudevents.V1.CloudEvent.Types;

const string ProjectId = "events-atamel";
const string Region = "us-central1";
const string Channel = "atamel-custom-events-channel";

var publisherClient = await PublisherClient.CreateAsync();

var ce = new CloudEvent
{
    Id = "12345",
    Source = "urn:from/client/library",
    SpecVersion = "1.0",
    TextData = "{\"message\": \"Hello world from client library\"}",
    Type = "mycompany.myorg.myproject.v1.myevent"
};

ce.Attributes.Add("datacontenttype", new CloudEventAttributeValue{CeString = "application/json"});
ce.Attributes.Add("someattribute", new CloudEventAttributeValue{CeString = "somevalue"});
//ce.Attributes.Add("time", new CloudEventAttributeValue{CeTimestamp = "2022-03-19T21:29:13.899-04:00"});

// var request = new PublishChannelConnectionEventsRequest
// {
//     ChannelConnection = $"projects/{ProjectId}/locations/{Region}/channels/{Channel}",
//     Events = { new Any(), },
// };
// var response = await publisherClient.PublishChannelConnectionEventsAsync(request);

var request = new PublishEventsRequest
{
    Channel = $"projects/{ProjectId}/locations/{Region}/channels/{Channel}",
    //Events = { new Any(), },
    Events = { Any.Pack(ce) }
};
var response = await publisherClient.PublishEventsAsync(request);
