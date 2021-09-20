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
using System;
using System.Collections.Generic;
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

        private const string DIRECT_SERVICE_CATALOG_FILE = "direct_services.json";

        // TODO: Externalize to a file if the list gets long at some point.
        private static HashSet<string> AUDITLOG_METHOD_NAMES_BLOCK_LIST = new HashSet<string> {
            "google.monitoring.v3.TimeSeriesFilterService.ParseTimeSeriesFilter"
        };
        private const string OUTPUT_GITHUB = "../README.md";
        private const string OUTPUT_DEVSITE = "../README_devsite.md";
        private static readonly HttpClient client = new HttpClient();

        static async Task Main(bool devsite = false)
        {
            Console.WriteLine($"Devsite? {devsite}");
            var output = devsite ? OUTPUT_DEVSITE : OUTPUT_GITHUB;

            using StreamWriter file = new(output);

            AddHeader(file);
            AddPubSubServices(file, devsite);
            await AddAuditLogServicesAsync(file, devsite);
            AddDirectServices(file, devsite);

            Console.WriteLine($"File generated: {output}");
        }

        private static void AddHeader(StreamWriter file)
        {
            file.WriteLine("# Events supported by Eventarc\n");
            file.WriteLine("The following is a list of the events supported by Eventarc.\n");
            file.WriteLine("- Using Pub/Sub");
            file.WriteLine("- Using Cloud Audit Logs");
            file.WriteLine("- Directly from a Google Cloud source");
        }

        private static void AddPubSubServices(StreamWriter file, bool devsite)
        {
            if (devsite)
            {
                file.WriteLine("\n## Using Pub/Sub\n");
                file.WriteLine("Requests to your service are triggered by messages published to a Pub/Sub topic.");
                file.WriteLine("For more information, see [Creating a trigger](/eventarc/docs/creating-triggers.md).");
            }
            else
            {
                file.WriteLine("\n### Using Cloud Pub/Sub");
            }

            var jsonString = File.ReadAllText(PUBSUB_SERVICE_CATALOG_FILE);
            var services = JsonSerializer.Deserialize<PubSubServices>(jsonString);
            var orderedServices = services.services.OrderByDescending(service => service.priority)
                .ThenBy(service => service.displayName);

            orderedServices.ToList().ForEach(service =>
            {
                if (devsite)
                {
                    if (string.IsNullOrEmpty(service.url))
                    {
                        file.WriteLine($"\n### {service.displayName}");
                    }
                    else
                    {
                        file.WriteLine($"\n### [{service.displayName}]({service.url})");
                    }

                    // Assuming one or the other
                    if (!string.IsNullOrEmpty(service.serviceName))
                    {
                        file.WriteLine($"\n- `{service.serviceName}`");
                    }
                    else if (!string.IsNullOrEmpty(service.description))
                    {
                        file.WriteLine($"\n- {service.description}");
                    }
                }
                else
                {
                    file.WriteLine($"<details><summary>{service.displayName}</summary>");
                    file.WriteLine("<p>\n");
                    // Assuming one or the other
                    if (!string.IsNullOrEmpty(service.serviceName))
                    {
                        file.Write($"`{service.serviceName}`");
                    }
                    else if (!string.IsNullOrEmpty(service.description))
                    {
                        file.Write($"{service.description}");
                    }
                    if (!string.IsNullOrEmpty(service.url)) file.WriteLine($" ([more info]({service.url}))");
                    file.WriteLine("\n</p>");
                    file.WriteLine("</details>");
                }
            });
        }

        private static async Task AddAuditLogServicesAsync(StreamWriter file, bool devsite)
        {
            if (devsite)
            {
                file.WriteLine("\n## Using Cloud Audit Logs\n");
                file.WriteLine("These `serviceName` and `methodName values` can be used to create the filters for Eventarc triggers. For more information, see [Creating a trigger](/eventarc/docs/creating-triggers.md).\n");
            }
            else
            {
                file.WriteLine("\n### Using Cloud Audit Logs");
            }

            var stream = await client.GetStreamAsync(AUDITLOG_SERVICE_CATALOG_URL);
            var services = await JsonSerializer.DeserializeAsync<AuditLogServices>(stream);
            var orderedServices = services.services.OrderBy(service => service.displayName);

            orderedServices.ToList().ForEach(service =>
            {
                if (devsite)
                {
                    file.WriteLine($"### {service.displayName}\n");
                    file.WriteLine("#### `serviceName`\n");
                    file.WriteLine($"- `{service.serviceName}`\n");
                    file.WriteLine("#### `methodName`\n");

                    var allowedMethods = service.methods.Where(method => !AUDITLOG_METHOD_NAMES_BLOCK_LIST.Contains(method.methodName)).ToList();
                    allowedMethods.ForEach(method => file.WriteLine($"- `{method.methodName}`"));
                    file.WriteLine("");
                }
                else
                {
                    file.WriteLine($"<details><summary>{service.displayName}</summary>");
                    file.WriteLine("<p>\n");
                    file.WriteLine($"`{service.serviceName}`\n");

                    var allowedMethods = service.methods.Where(method => !AUDITLOG_METHOD_NAMES_BLOCK_LIST.Contains(method.methodName)).ToList();
                    allowedMethods.ForEach(method => file.WriteLine($"* `{method.methodName}`"));
                    file.WriteLine("\n</p>");
                    file.WriteLine("</details>");
                }
            });
        }

        private static void AddDirectServices(StreamWriter file, bool devsite)
        {
            if (devsite)
            {
                file.WriteLine("## Directly from a Google Cloud source\n");
                file.WriteLine("For more information, see [Creating a trigger](/eventarc/docs/creating-triggers.md).");
            }
            else
            {
                file.WriteLine("\n### Directly from a Google Cloud source");
            }

            var jsonString = File.ReadAllText(DIRECT_SERVICE_CATALOG_FILE);
            var services = JsonSerializer.Deserialize<DirectServices>(jsonString);

            services.services.ForEach(service =>
            {
                if (devsite)
                {
                    file.WriteLine($"\n### {service.displayName}\n");
                    service.events.ForEach(current => file.WriteLine($"- `{current}`"));
                }
                else
                {
                    file.WriteLine($"<details><summary>{service.displayName}</summary>");
                    file.WriteLine("<p>\n");
                    service.events.ForEach(current => file.WriteLine($"* `{current}`"));
                    file.WriteLine("\n</p>");
                    file.WriteLine("</details>");
                }
            });
        }
    }
}
