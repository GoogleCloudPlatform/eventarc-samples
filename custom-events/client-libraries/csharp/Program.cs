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
using Io.Cloudevents.V1;
using static Io.Cloudevents.V1.CloudEvent.Types;

var commandArgs = Environment.GetCommandLineArgs();
var ProjectId = commandArgs[1]; // "your-project-id";
var Region = commandArgs[2];    // "us-central1";
var Channel = commandArgs[3];   // "hello-custom-events-channel";
Console.WriteLine($"ProjectId: {ProjectId}, Region: {Region}, Channel: {Channel}");

var publisherClient = await PublisherClient.CreateAsync();

var ce = new CloudEvent
{
    Id = "12345",
    Source = "urn:from/csharp",
    SpecVersion = "1.0",
    TextData = "{\"message\": \"Hello world from C# client library\"}",
    Type = "mycompany.myorg.myproject.v1.myevent"
};

ce.Attributes.Add("datacontenttype", new CloudEventAttributeValue{CeString = "application/json"});
ce.Attributes.Add("someattribute", new CloudEventAttributeValue{CeString = "somevalue"});
ce.Attributes.Add("time", new CloudEventAttributeValue{CeTimestamp = Timestamp.FromDateTime(DateTime.UtcNow)});

var request = new PublishEventsRequest
{
    Channel = $"projects/{ProjectId}/locations/{Region}/channels/{Channel}",
    Events = { Any.Pack(ce) }
};
var response = await publisherClient.PublishEventsAsync(request);
Console.WriteLine("Event published!");