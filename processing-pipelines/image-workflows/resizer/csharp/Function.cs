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
using Google.Cloud.Storage.V1;
using Common;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace Resizer
{
    public class Function : IHttpFunction
    {
        private const int ThumbWidth = 400;
        private const int ThumbHeight = 400;

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

                using (var inputStream = new MemoryStream())
                {
                    var client = await StorageClient.CreateAsync();
                    await client.DownloadObjectAsync(bucket, file, inputStream);
                    _logger.LogInformation($"Downloaded '{file}' from bucket '{bucket}'");

                    using (var outputStream = new MemoryStream())
                    {
                        inputStream.Position = 0; // Reset to read
                        using (Image image = Image.Load(inputStream))
                        {
                            image.Mutate(x => x
                                .Resize(ThumbWidth, ThumbHeight)
                            );
                            _logger.LogInformation($"Resized image '{file}' to {ThumbWidth}x{ThumbHeight}");

                            image.SaveAsPng(outputStream);
                        }

                        var outputFile = $"{Path.GetFileNameWithoutExtension(file)}-{ThumbWidth}x{ThumbHeight}.png";
                        await client.UploadObjectAsync(_outputBucket, outputFile, "image/png", outputStream);
                        _logger.LogInformation($"Uploaded '{outputFile}' to bucket '{_outputBucket}'");

                        var replyData = new {bucket = _outputBucket, file = outputFile};
                        var json = JsonConvert.SerializeObject(replyData);
                        _logger.LogInformation($"Replying back with json: {json}");

                        context.Response.ContentType = "application/json";
                        await context.Response.WriteAsync(json);
                    }
                }
            }
            catch (Exception e)
            {
                _logger.LogError($"Error processing: " + e.Message);
                throw e;
            }
        }
    }
}
