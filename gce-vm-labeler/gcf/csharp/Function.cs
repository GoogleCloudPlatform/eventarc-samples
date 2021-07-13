// Copyright 2021 Google LLC
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
using CloudNative.CloudEvents;
using Google.Cloud.Compute.V1;
using Google.Cloud.Functions.Framework;
using Google.Events.Protobuf.Cloud.Audit.V1;
using Microsoft.Extensions.Logging;
using System.Threading;
using System.Threading.Tasks;

namespace GceVmLabeler
{
    public class Function : ICloudEventFunction<LogEntryData>
    {
        private readonly ILogger _logger;

        public Function(ILogger<Function> logger) =>
            _logger = logger;

        public async Task HandleAsync(CloudEvent cloudEvent, LogEntryData data, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Event type: {type}", cloudEvent.Type);

            if (!data.Operation.Last)
            {
                _logger.LogInformation("Operation is not last, skipping event");
                return;
            }

            // projects/events-atamel/zones/us-central1-a/instances/instance-1
            var resourceName = data.ProtoPayload.ResourceName;
            _logger.LogInformation($"Resource: {resourceName}");

            var tokens = resourceName.Split("/");
            var project = tokens[1];
            var zone = tokens[3];
            var instance = tokens[5];
            var username = data.ProtoPayload.AuthenticationInfo.PrincipalEmail.Split("@")[0];

            _logger.LogInformation($"Setting label 'username:{username}' to instance '{instance}'");

            await SetLabelsAsync(project, zone, instance, username);

            _logger.LogInformation($"Set label 'user:{username}' to instance '{instance}'");
        }

        private static async Task SetLabelsAsync(string project, string zone, string instance, string username)
        {
            var currentInstance = await GetInstance(project, zone, instance);

            var labels = currentInstance.Labels;
            labels.Add("username", username);

            var request = new SetLabelsInstanceRequest
            {
                Project = project,
                Zone = zone,
                Instance = instance,
                InstancesSetLabelsRequestResource = new InstancesSetLabelsRequest
                {
                    Labels = { labels },
                    LabelFingerprint = currentInstance.LabelFingerprint
                }
            };

            var client = await InstancesClient.CreateAsync();
            await client.SetLabelsAsync(request);
        }

        private static async Task<Instance> GetInstance(string project, string zone, string instance)
        {
            var client = await InstancesClient.CreateAsync();
            var currentInstance = await client.GetAsync(project, zone, instance);
            return currentInstance;
        }
    }
}
