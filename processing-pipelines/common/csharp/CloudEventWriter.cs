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
using System;
using System.Threading.Tasks;
using CloudNative.CloudEvents;
using CloudNative.CloudEvents.NewtonsoftJson;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Text;
using CloudNative.CloudEvents.AspNetCore;

namespace Common
{
    public class CloudEventWriter : IEventWriter
    {
        private static readonly CloudEventFormatter formatter = new JsonEventFormatter();

        private readonly string _eventSource;
        private readonly string _eventType;
        private readonly ILogger _logger;

        public CloudEventWriter(string eventSource, string eventType, ILogger logger)
        {
            _eventSource = eventSource;
            _eventType = eventType;
            _logger = logger;
        }

        public async Task Write(string eventData, HttpContext context)
        {
            var replyEvent = new CloudEvent
            {
                Type = _eventType,
                Source = new Uri($"urn:{_eventSource}"),
                Time = DateTimeOffset.Now,
                DataContentType = "application/json",
                Id = Guid.NewGuid().ToString(),
                Data = eventData
            };
            _logger.LogInformation("Replying with CloudEvent\n" + replyEvent.GetLog());

            await replyEvent.CopyToHttpResponseAsync(context.Response, ContentMode.Binary, formatter);
        }
    }
}