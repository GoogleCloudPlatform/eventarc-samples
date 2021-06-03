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
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

namespace EventListGenerator
{
    class Program
    {
        private const string PUBSUB_SERVICE_CATALOG_FILE = "pubsub_services.json";
        private const string AUDITLOG_SERVICE_CATALOG_URL = "https://raw.githubusercontent.com/googleapis/google-cloudevents/master/json/audit/service_catalog.json";
        private static readonly HttpClient client = new HttpClient();

        static async Task Main(string[] args)
        {
            using StreamWriter file = new("../README.md");

            AddHeader(file);
            AddPubSubServices(file);
            await AddAuditLogServicesAsync(file);
        }

        private static void AddHeader(StreamWriter file)
        {
            file.WriteLineAsync("# Eventarc Events\n");
            file.WriteLine("The list of events supported by Eventarc.");
        }

        private static async Task AddAuditLogServicesAsync(StreamWriter file)
        {
            file.WriteLine("\n### via Cloud Audit Logs");

            var stream = await client.GetStreamAsync(AUDITLOG_SERVICE_CATALOG_URL);
            var services = await JsonSerializer.DeserializeAsync<AuditLogServices>(stream);
            var orderedServices = services.services.OrderBy(service => {
                return string.IsNullOrEmpty(service.displayName) ? service.serviceName : service.displayName;
            });

            orderedServices.ToList().ForEach(service =>
            {
                var displayName = string.IsNullOrEmpty(service.displayName) ? service.serviceName : service.displayName;
                file.WriteLine($"<details><summary>{displayName}</summary>");
                file.WriteLine("<p>\n");
                file.WriteLine($"`{service.serviceName}`\n");
                service.methods.ForEach(method => file.WriteLine($"* `{method.methodName}`"));
                file.WriteLine("\n</p>");
                file.WriteLine("</details>");
            });
        }

        private static void AddPubSubServices(StreamWriter file)
        {
            file.WriteLine("\n### via Cloud Pub/Sub");

            var jsonString = File.ReadAllText(PUBSUB_SERVICE_CATALOG_FILE);
            var services = JsonSerializer.Deserialize<PubSubServices>(jsonString);
            var orderedServices = services.services.OrderBy(service => {
                return string.IsNullOrEmpty(service.displayName) ? service.serviceName : service.displayName;
            });

            orderedServices.ToList().ForEach(service =>
            {
                var displayName = string.IsNullOrEmpty(service.displayName) ? service.serviceName : service.displayName;
                file.WriteLine($"<details><summary>{displayName}</summary>");
                file.WriteLine("<p>\n");
                file.Write($"`{service.serviceName}`");
                file.WriteLine(string.IsNullOrEmpty(service.url)? "\n" : $" ([More info]({service.url}))\n");
                file.WriteLine("</p>");
                file.WriteLine("</details>");
            });
        }
    }
}
