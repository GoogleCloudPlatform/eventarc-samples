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
using Google.Cloud.Functions.Framework;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using System.IO;
using Newtonsoft.Json;
using System;
using Google.Cloud.Vision.V1;
using Common;

namespace Filter
{
    public class Function : IHttpFunction
    {
        private readonly ILogger _logger;

        private readonly HttpRequestReader _requestReader;

        public Function(ILogger<Function> logger)
        {
            _logger = logger;
            var configReader = new ConfigReader(logger);
            _requestReader = new HttpRequestReader(logger);
        }

        public async Task HandleAsync(HttpContext context)
        {
            _logger.LogInformation("Function received request");

            try
            {
                var (bucket, file) = await _requestReader.ReadCloudStorageData(context);

                var storageUrl = $"gs://{bucket}/{file}";
                _logger.LogInformation($"Storage url: {storageUrl}");

                var safe = await IsPictureSafe(storageUrl);
                _logger.LogInformation($"Is the picture safe? {safe}");

                var replyData = new {safe = safe};
                var json = JsonConvert.SerializeObject(replyData);
                _logger.LogInformation($"Replying back with json: {json}");

                context.Response.ContentType = "application/json";
                await context.Response.WriteAsync(json);
            }
            catch (Exception e)
            {
                _logger.LogError($"Error processing: " + e.Message);
                throw e;
            }
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
    }
}
