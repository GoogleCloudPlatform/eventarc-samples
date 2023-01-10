// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// [START eventarc_third_party_publish_csharp]
using Google.Cloud.Eventarc.Publishing.V1;
using CloudNative.CloudEvents;
using CloudNative.CloudEvents.Protobuf;
using CloudNative.CloudEvents.SystemTextJson;
using System.Net.Mime;
using Newtonsoft.Json;
using Google.Protobuf.WellKnownTypes;

var commandArgs = Environment.GetCommandLineArgs();
var ProjectId = commandArgs[1];
var Region = commandArgs[2];
var ChannelConnection = commandArgs[3];
// Controls the format of events sent to Eventarc.
// 'true' for using text format.
// 'false' for proto (preferred) format.
bool UseTextEvent = commandArgs.Length > 4 ? bool.TryParse(commandArgs[4], out UseTextEvent) : false;

var FullChannelName = $"projects/{ProjectId}/locations/{Region}/channels/{ChannelConnection}";
Console.WriteLine($"Channel: {FullChannelName}");
Console.WriteLine($"UseTextEvent: {UseTextEvent}");

var publisherClient = await PublisherClient.CreateAsync();

//Construct the CloudEvent and set necessary attributes.
var cloudEventAttributes = new[]
{
    CloudEventAttribute.CreateExtension("someattribute", CloudEventAttributeType.String)
};

var cloudEvent = new CloudEvent(cloudEventAttributes)
{
    Id = Guid.NewGuid().ToString(),
    // Note: Type has to match with the client trigger!
    Type = "provider.v1.event",
    Source = new Uri("//provider/source"),
    DataContentType = MediaTypeNames.Application.Json,
    Data = JsonConvert.SerializeObject(new { Message = "Hello World from C#"}),
    Time = DateTimeOffset.UtcNow,
    // Note: someattribute and somevalue have to match with the client trigger!
    ["someattribute"] = "somevalue"
};

PublishChannelConnectionEventsRequest request;

if (UseTextEvent)
{
    // Convert the CloudEvent to JSON
    var formatter = new JsonEventFormatter();
    var cloudEventJson = formatter.ConvertToJsonElement(cloudEvent).ToString();
    Console.WriteLine($"Sending CloudEvent: {cloudEventJson}");
    request = new PublishChannelConnectionEventsRequest
    {
        ChannelConnection = FullChannelName,
        TextEvents = { cloudEventJson }
    };
}
else
{
    // Convert the CloudEvent to Proto
    var formatter = new ProtobufEventFormatter();
    var cloudEventProto = formatter.ConvertToProto(cloudEvent);
    Console.WriteLine($"Sending CloudEvent: {cloudEventProto}");
    request = new PublishChannelConnectionEventsRequest
    {
        ChannelConnection = FullChannelName,
        Events = { Any.Pack(cloudEventProto) }
    };
}

var response = await publisherClient.PublishChannelConnectionEventsAsync(request);
Console.WriteLine("Event published!");
// [END eventarc_third_party_publish_csharp]
