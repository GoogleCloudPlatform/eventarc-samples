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
using System.Threading.Tasks;
using Common;
using Google.Cloud.Vision.V1;
using Google.Cloud.Workflows.Common.V1;
using Google.Cloud.Workflows.Executions.V1;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Filter
{
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILogger<Startup> logger)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            logger.LogInformation("Service is starting...");

            app.UseRouting();

            var eventReader = new CloudEventReader(logger);

            var configReader = new ConfigReader(logger);
            var projectId = configReader.Read("PROJECT_ID");
            var region = configReader.Read("REGION");
            var workflow = configReader.Read("WORKFLOW_NAME");
            var labelerUrl = configReader.Read("LABELER_URL");
            var resizerUrl = configReader.Read("RESIZER_URL");
            var watermarkerUrl = configReader.Read("WATERMARKER_URL");

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapPost("/", async context =>
                {
                    var (bucket, file) = await eventReader.ReadCloudStorageData(context);

                    var storageUrl = $"gs://{bucket}/{file}";
                    logger.LogInformation($"Storage url: {storageUrl}");

                    var safe = await IsPictureSafe(storageUrl);
                    logger.LogInformation($"Is the picture safe? {safe}");

                    if (!safe)
                    {
                        return;
                    }

                    var args = JsonConvert.SerializeObject(new {
                        bucket = bucket,
                        file = file,
                        urls = new {
                            LABELER_URL = labelerUrl,
                            RESIZER_URL = resizerUrl,
                            WATERMARKER_URL = watermarkerUrl}
                        }
                    );

                    logger.LogInformation($"Creating workflows execution with arg: {args}");

                    var response = await ExecuteWorkflow(projectId, region, workflow, args);

                    logger.LogInformation($"Created workflows execution: {response.Name}");
                });
            });
        }

        private async Task<bool> IsPictureSafe(string storageUrl)
        {
            var visionClient = ImageAnnotatorClient.Create();
            var response = await visionClient.DetectSafeSearchAsync(Image.FromUri(storageUrl));
            return response.Adult < Likelihood.Possible
                && response.Medical < Likelihood.Possible
                && response.Racy < Likelihood.Possible
                && response.Spoof < Likelihood.Possible
                && response.Violence < Likelihood.Possible;
        }

        private async Task<Execution> ExecuteWorkflow(string projectId, string region, string workflow, string args)
        {
            var client = await ExecutionsClient.CreateAsync();

            var request = new CreateExecutionRequest() {
                Parent = WorkflowName.Format(projectId, region, workflow),
                Execution = new Execution() {
                    Argument = args
                }
            };

            var response = await client.CreateExecutionAsync(request);
            return response;
       }
    }
}
