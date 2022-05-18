// Copyright 2022 Google LLC
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

using Google.Cloud.Eventarc.Publishing.V1;
using Google.Protobuf.WellKnownTypes;
using CloudNative.CloudEvents;
using CloudNative.CloudEvents.Protobuf;

var commandArgs = Environment.GetCommandLineArgs();
var ProjectId = commandArgs[1]; // "your-project-id";
var Region = commandArgs[2];    // "us-central1";
var Channel = commandArgs[3];   // "hello-custom-events-channel";
Console.WriteLine($"ProjectId: {ProjectId}, Region: {Region}, Channel: {Channel}");

var publisherClient = await PublisherClient.CreateAsync();

//Construct the CloudEvent and set necessary attributes.
var cloudEventAttributes = new[]
{
    CloudEventAttribute.CreateExtension("someattribute", CloudEventAttributeType.String),
    CloudEventAttribute.CreateExtension("temperature", CloudEventAttributeType.Integer),
    CloudEventAttribute.CreateExtension("weather", CloudEventAttributeType.String),
};

var cloudEvent = new CloudEvent(cloudEventAttributes)
{
    Id = "12345",
    Type = "example.v1.event",
    Source = new Uri("urn:from/client/library"),
    Subject = "test-event-subject",
    DataContentType = "application/json",
    Data = "{\"message\": \"Test Event using Client Library\"}",
    Time = DateTimeOffset.UtcNow,
    ["somattribute"] = "some value",
    ["temperature"] = 5,
    ["weather"] = "sunny"
};

 //Convert the CloudEvent to proto format using the proto converter
var cloudEventProto = new ProtobufEventFormatter().ConvertToProto(cloudEvent);

var request = new PublishEventsRequest
{
    Channel = $"projects/{ProjectId}/locations/{Region}/channels/{Channel}",
    Events = { Any.Pack(cloudEventProto) }
};
var response = await publisherClient.PublishEventsAsync(request);
Console.WriteLine("Event published!");