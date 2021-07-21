// Copyright 2020 Google LLC
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
using System.Threading.Tasks;
using CloudNative.CloudEvents;
using CloudNative.CloudEvents.AspNetCore;
using CloudNative.CloudEvents.NewtonsoftJson;
using Google.Events.Protobuf.Cloud.Audit.V1;
using Google.Events.Protobuf.Cloud.PubSub.V1;
using Google.Events.Protobuf.Cloud.Scheduler.V1;
using Google.Events.Protobuf.Cloud.Storage.V1;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace Common
{
    public class CloudEventReader
    {
        private const string EVENT_TYPE_AUDITLOG = "google.cloud.audit.log.v1.written";
        private const string EVENT_TYPE_PUBSUB = "google.cloud.pubsub.topic.v1.messagePublished";

        private const string EVENT_TYPE_SCHEDULER = "google.cloud.scheduler.job.v1.executed";

        private const string EVENT_TYPE_STORAGE = "google.cloud.storage.object.v1.finalized";

        private readonly ILogger _logger;

        public CloudEventReader(ILogger logger)
        {
            _logger = logger;
        }

        public async Task<(string, string)> ReadCloudStorageData(HttpContext context)
        {
            _logger.LogInformation("Reading cloud storage data");


            string bucket = null, name = null;
            CloudEvent cloudEvent;
            CloudEventFormatter formatter;
            var ceType = context.Request.Headers["ce-type"];

            switch (ceType)
            {
                case EVENT_TYPE_AUDITLOG:
                    //"protoPayload" : {"resourceName":"projects/_/buckets/events-atamel-images-input/objects/atamel.jpg}";
                    formatter = CloudEventFormatterAttribute.CreateFormatter(typeof(LogEntryData));
                    cloudEvent = await context.Request.ToCloudEventAsync(formatter);
                    _logger.LogInformation($"Received CloudEvent\n{cloudEvent.GetLog()}");

                    var logEntryData = (LogEntryData)cloudEvent.Data;
                    var tokens = logEntryData.ProtoPayload.ResourceName.Split('/');
                    bucket = tokens[3];
                    name = tokens[5];
                    break;
                case EVENT_TYPE_STORAGE:
                    formatter = CloudEventFormatterAttribute.CreateFormatter(typeof(StorageObjectData));
                    cloudEvent = await context.Request.ToCloudEventAsync(formatter);
                    _logger.LogInformation($"Received CloudEvent\n{cloudEvent.GetLog()}");

                    var storageObjectData = (StorageObjectData)cloudEvent.Data;
                    bucket = storageObjectData.Bucket;
                    name = storageObjectData.Name;
                    break;
                case EVENT_TYPE_PUBSUB:
                    // {"message": {
                    //     "data": "eyJidWNrZXQiOiJldmVudHMtYXRhbWVsLWltYWdlcy1pbnB1dCIsIm5hbWUiOiJiZWFjaC5qcGcifQ==",
                    // },"subscription": "projects/events-atamel/subscriptions/cre-europe-west1-trigger-resizer-sub-000"}
                    formatter = CloudEventFormatterAttribute.CreateFormatter(typeof(MessagePublishedData));
                    cloudEvent = await context.Request.ToCloudEventAsync(formatter);
                    _logger.LogInformation($"Received CloudEvent\n{cloudEvent.GetLog()}");

                    var messagePublishedData = (MessagePublishedData)cloudEvent.Data;
                    var pubSubMessage = messagePublishedData.Message;
                    _logger.LogInformation($"Type: {EVENT_TYPE_PUBSUB} data: {pubSubMessage.Data.ToBase64()}");

                    var decoded = pubSubMessage.Data.ToStringUtf8();
                    _logger.LogInformation($"decoded: {decoded}");

                    var parsed = JValue.Parse(decoded);
                    bucket = (string)parsed["bucket"];
                    name = (string)parsed["name"];
                    break;
                default:
                    // Data:
                    // {"bucket":"knative-atamel-images-input","name":"beach.jpg"}
                    formatter = new JsonEventFormatter();
                    cloudEvent = await context.Request.ToCloudEventAsync(formatter);
                    _logger.LogInformation($"Received CloudEvent\n{cloudEvent.GetLog()}");

                    dynamic data = cloudEvent.Data;
                    bucket = data.bucket;
                    name = data.name;
                    break;
            }
            _logger.LogInformation($"Extracted bucket: {bucket} and name: {name}");
            return (bucket, name);
        }

        public async Task<string> ReadCloudSchedulerData(HttpContext context)
        {
            _logger.LogInformation("Reading cloud scheduler data");

            string country = null;
            CloudEvent cloudEvent;
            CloudEventFormatter formatter;
            var ceType = context.Request.Headers["ce-type"];

            switch (ceType)
            {
                case EVENT_TYPE_PUBSUB:
                    formatter = CloudEventFormatterAttribute.CreateFormatter(typeof(MessagePublishedData));
                    cloudEvent = await context.Request.ToCloudEventAsync(formatter);
                    _logger.LogInformation($"Received CloudEvent\n{cloudEvent.GetLog()}");

                    var messagePublishedData = (MessagePublishedData)cloudEvent.Data;
                    var pubSubMessage = messagePublishedData.Message;
                    _logger.LogInformation($"Type: {EVENT_TYPE_PUBSUB} data: {pubSubMessage.Data.ToBase64()}");

                    country = pubSubMessage.Data.ToStringUtf8();
                    break;
                case EVENT_TYPE_SCHEDULER:
                    // Data: {"custom_data":"Q3lwcnVz"}
                    formatter = CloudEventFormatterAttribute.CreateFormatter(typeof(SchedulerJobData));
                    cloudEvent = await context.Request.ToCloudEventAsync(formatter);
                    _logger.LogInformation($"Received CloudEvent\n{cloudEvent.GetLog()}");

                    var schedulerJobData = (SchedulerJobData)cloudEvent.Data;
                    _logger.LogInformation($"Type: {EVENT_TYPE_SCHEDULER} data: {schedulerJobData.CustomData.ToBase64()}");

                    country = schedulerJobData.CustomData.ToStringUtf8();
                    break;
            }

            _logger.LogInformation($"Extracted country: {country}");
            return country;
        }
    }
}