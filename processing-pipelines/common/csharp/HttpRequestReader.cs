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
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Common
{
    public class HttpRequestReader
    {
        private readonly ILogger _logger;

        public HttpRequestReader(ILogger logger) => _logger = logger;

        public async Task<(string, string)> ReadCloudStorageData(HttpContext context)
        {
            _logger.LogInformation("Reading cloud storage data");

            // {"bucket": "workflows-atamel-input-files", "file": "atamel.jpg"}
            using TextReader reader = new StreamReader(context.Request.Body);
            var json = await reader.ReadToEndAsync();
            dynamic obj = JsonConvert.DeserializeObject(json);

            _logger.LogInformation($"Extracted bucket: {obj.bucket} and name: {obj.file}");
            return (obj.bucket, obj.file);
        }

        public async Task<(string, string, string)> ReadCloudStorageAndLabelsData(HttpContext context)
        {
            _logger.LogInformation("Reading cloud storage and labels data");

            // {"bucket": "workflows-atamel-input-files", "file": "atamel.jpg", "labels": "hello,beautiful,world"}
            using TextReader reader = new StreamReader(context.Request.Body);
            var json = await reader.ReadToEndAsync();
            dynamic obj = JsonConvert.DeserializeObject(json);

            _logger.LogInformation($"Extracted bucket: {obj.bucket}, name: {obj.file} and labels: {obj.labels}");
            return (obj.bucket, obj.file, obj.labels);
        }
    }
}