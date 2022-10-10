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
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Octokit;

namespace EventListGenerator
{
    class Program
    {
        private const string AUDITLOG_SERVICE_CATALOG_URL = "https://raw.githubusercontent.com/googleapis/google-cloudevents/master/json/audit/service_catalog.json";
        private const string DIRECT_SERVICE_CATALOG_FILE = "direct_services.json";
        private const string THIRDPARTY_SERVICE_CATALOG_FILE = "thirdparty_services.json";
        // TODO: Externalize to a file if the list gets long at some point.
        private static HashSet<string> AUDITLOG_METHOD_NAMES_BLOCK_LIST = new HashSet<string> {
            "google.monitoring.v3.TimeSeriesFilterService.ParseTimeSeriesFilter"
        };
        private const string HEADER_DIRECT = "Directly from a Google Cloud source";
        private const string HEADER_AUDITLOG = "Using Cloud Audit Logs";
        private const string HEADER_THIRDPARTY = "Using third-party sources";
        private const string OUTPUT_FOLDER = "output";
        private const string OUTPUT_GITHUB = "README.md";
        private const string OUTPUT_DEVSITE = "README_devsite.md";
        private const string GITHUB_OWNER = "GoogleCloudPlatform";
        private const string GITHUB_REPO = "eventarc-samples";
        private const string GITHUB_BRANCH = "main";
        private const string GITHUB_OUTPUT_PATH = "eventarc-events/EventListGenerator/";

        private static readonly HttpClient client = new HttpClient();

        static async Task Main()
        {
            await GenerateFile(false);
            await GenerateFile(true);
        }

        private async static Task GenerateFile(bool devsite)
        {
            Directory.CreateDirectory(OUTPUT_FOLDER);

            var filePath = devsite ? OUTPUT_FOLDER + "/" + OUTPUT_DEVSITE : OUTPUT_FOLDER + "/" + OUTPUT_GITHUB;
            using StreamWriter file = new(filePath);

            AddHeader(file, devsite);
            DoAddServices(HEADER_DIRECT, DIRECT_SERVICE_CATALOG_FILE, file, devsite);
            await AddAuditLogServicesAsync(file, devsite);
            DoAddServices(HEADER_THIRDPARTY, THIRDPARTY_SERVICE_CATALOG_FILE, file, devsite);

            // Important to close the stream before trying to do anything else
            file.Close();
            Console.WriteLine($"File generated: {filePath}");

            await CommitToGitHub(filePath);
        }

        private static void AddHeader(StreamWriter file, bool devsite)
        {
            file.WriteLine("# Events supported by Eventarc\n");
            file.WriteLine("The following is a list of the events supported by Eventarc.\n");
            file.WriteLine($"- [{HEADER_DIRECT}]"
                + (devsite ?
                "(/eventarc/docs/reference/supported-events#directly-from-a-google-cloud-source)" :
                "(#directly-from-a-google-cloud-source)"));
            file.WriteLine($"- [{HEADER_AUDITLOG}]"
                + (devsite ?
                "(/eventarc/docs/reference/supported-events#using-cloud-audit-logs)" :
                "(#using-cloud-audit-logs)"));

            file.WriteLine($"- [{HEADER_THIRDPARTY}]"
                + (devsite ?
                "(/eventarc/docs/reference/supported-events#using-third-party-sources)" :
                "(#using-third-party-sources)"));

            file.WriteLine("\nNote: Since Google Cloud IoT Core is being retired on August 16, 2023, the Cloud IoT events will also be deprecated at that time. Contact your Google Cloud account team for more information.");
        }

        private static async Task AddAuditLogServicesAsync(StreamWriter file, bool devsite)
        {
            if (devsite)
            {
                file.WriteLine($"\n## {HEADER_AUDITLOG}\n");
                file.WriteLine("These `serviceName` and `methodName values` can be used to create the filters for Eventarc triggers. For more information, see [All trigger targets](/eventarc/docs/targets.md).\n");
            }
            else
            {
                file.WriteLine($"\n### {HEADER_AUDITLOG}");
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
        private static void DoAddServices(string title, string catalogFile, StreamWriter file, bool devsite)
        {
            if (devsite)
            {
                file.WriteLine($"\n## {title}\n");
                file.WriteLine("For more information, see [All trigger targets](/eventarc/docs/targets.md).");
            }
            else
            {
                file.WriteLine($"\n### {title}");
            }

            var jsonString = File.ReadAllText(catalogFile);
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

        private static async Task CommitToGitHub(string filePath)
        {
            var token = Environment.GetEnvironmentVariable("GITHUB_TOKEN");
            if (string.IsNullOrEmpty(token))
            {
                return;
            }

            var gitHubClient = new GitHubClient(new ProductHeaderValue("EventListGenerator"));
            gitHubClient.Credentials = new Credentials(token);

            var gitHubFilePath = Path.Combine(GITHUB_OUTPUT_PATH, filePath);

            var fileDetails = await gitHubClient.Repository.Content.GetAllContentsByRef(GITHUB_OWNER, GITHUB_REPO,
                gitHubFilePath, GITHUB_BRANCH);

            var updateResult = await gitHubClient.Repository.Content.UpdateFile(GITHUB_OWNER, GITHUB_REPO,
                gitHubFilePath, new UpdateFileRequest($"Automatic update of {Path.GetFileName(filePath)}", File.ReadAllText(filePath), fileDetails.First().Sha));

            Console.WriteLine($"File committed to GitHub: {updateResult.Commit.Sha}");
        }
    }
}
