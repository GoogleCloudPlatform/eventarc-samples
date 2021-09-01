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
using System.Text;
using Google.Cloud.Vision.V1;
using Google.Cloud.Storage.V1;
using System.Linq;
using Common;

namespace Labeler
{
    public class Function : IHttpFunction
    {
        private readonly ILogger _logger;

        private readonly string _outputBucket;
        private readonly HttpRequestReader _requestReader;

        public Function(ILogger<Function> logger)
        {
            _logger = logger;
            var configReader = new ConfigReader(logger);
            _outputBucket = configReader.Read("BUCKET");
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

                var labels = await ExtractLabelsAsync(storageUrl);
                _logger.LogInformation($"This picture is labelled: {labels}");

                using (var outputStream = new MemoryStream(Encoding.UTF8.GetBytes(labels)))
                {
                    var outputObjectName = $"{Path.GetFileNameWithoutExtension(file)}-labels.txt";
                    var client = await StorageClient.CreateAsync();
                    await client.UploadObjectAsync(_outputBucket, outputObjectName, "text/plain", outputStream);
                    _logger.LogInformation($"Uploaded '{outputObjectName}' to bucket '{_outputBucket}'");
                }
            }
            catch (Exception e)
            {
                _logger.LogError($"Error processing: " + e.Message);
                throw e;
            }
        }

        private async Task<string> ExtractLabelsAsync(string storageUrl)
        {
            var visionClient = ImageAnnotatorClient.Create();
            var labels = await visionClient.DetectLabelsAsync(Image.FromUri(storageUrl), maxResults: 10);

            var orderedLabels = labels
                .OrderByDescending(x => x.Score)
                .TakeWhile((x, i) => i <= 2 || x.Score > 0.50)
                .Select(x => x.Description)
                .ToList();

            return string.Join(",", orderedLabels.ToArray());
        }
    }
}
