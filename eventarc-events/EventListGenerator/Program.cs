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
        private const string DIRECT_SERVICE_CATALOG_FILE = "services.json";
        private const string DIRECT_SERVICE_CATALOG_URL = $"https://raw.githubusercontent.com/GoogleCloudPlatform/eventarc-samples/main/eventarc-events/EventListGenerator/{DIRECT_SERVICE_CATALOG_FILE}";
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

        static async Task Main(string[] args)
        {
            bool localServiceCatalogFile = false;
            if (args.Length > 0)
            {
                bool.TryParse(args[0], out localServiceCatalogFile);
            }
            await GenerateFile(false, localServiceCatalogFile);
            await GenerateFile(true, localServiceCatalogFile);
        }

        private async static Task GenerateFile(bool devsite, bool localServiceCatalogFile = false)
        {
            Directory.CreateDirectory(OUTPUT_FOLDER);

            var filePath = devsite ? OUTPUT_FOLDER + "/" + OUTPUT_DEVSITE : OUTPUT_FOLDER + "/" + OUTPUT_GITHUB;
            using StreamWriter file = new(filePath);

            AddHeader(file, devsite);
            Console.WriteLine($"Using local service catalog file? {localServiceCatalogFile}");
            await AddServices(HEADER_DIRECT, file, devsite, localServiceCatalogFile);
            await AddAuditLogServicesAsync(file, devsite);
            await AddServices(HEADER_THIRDPARTY, file, devsite, localServiceCatalogFile);

            // Important to close the stream before trying to do anything else
            file.Close();
            Console.WriteLine($"File generated: {filePath}");

            await CommitToGitHub(filePath);
        }

        private static void AddHeader(StreamWriter file, bool devsite)
        {
            file.WriteLine("# Events supported by Eventarc\n");
            file.WriteLine("The following is a list of the event types supported by Eventarc.\n");
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

            file.WriteLine("\nNote: Google Cloud IoT Core was retired on August 16, 2023, and Cloud IoT events were deprecated at that time. Contact your Google Cloud account team for more information.");
        }

        private static async Task AddAuditLogServicesAsync(StreamWriter file, bool devsite)
        {
            if (devsite)
            {
                file.WriteLine($"\n## {HEADER_AUDITLOG}\n");
                file.WriteLine("These `serviceName` and `methodName` values can be used to create the filters for Eventarc triggers. For more information, see [Event providers and destinations](/eventarc/docs/event-providers-targets).\n");
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
                service.WriteToStream(file, devsite);
            });
        }
        private static async Task AddServices(string title, StreamWriter file, bool devsite, bool localServiceCatalogFile)
        {
            if (devsite)
            {
                file.WriteLine($"\n## {title}\n");
                file.WriteLine("For more information, see [Event providers and destinations](/eventarc/docs/event-providers-targets).");
            }
            else
            {
                file.WriteLine($"\n### {title}");
            }

            Services services;
            if (localServiceCatalogFile)
            {
                var jsonString = File.ReadAllText(DIRECT_SERVICE_CATALOG_FILE);
                services = JsonSerializer.Deserialize<Services>(jsonString);
            }
            else
            {
                var stream = await client.GetStreamAsync(DIRECT_SERVICE_CATALOG_URL);
                services = await JsonSerializer.DeserializeAsync<Services>(stream);
            }

            var filteredServices = title == HEADER_DIRECT ? services.direct : services.thirdParty;
            var orderedServices = filteredServices.OrderBy(service => service.displayName);

            orderedServices.ToList().ForEach(service =>
            {
                service.WriteToStream(file, devsite);
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
