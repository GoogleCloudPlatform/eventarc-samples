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
using System;
using Google.Cloud.Storage.V1;
using Common;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using SixLabors.Fonts;
using SixLabors.ImageSharp.Drawing.Processing;

// Based on https://github.com/SixLabors/Samples/blob/master/ImageSharp/DrawWaterMarkOnImage/Program.cs
namespace Watermarker
{
    public class Function : IHttpFunction
    {
        private readonly ILogger _logger;

        private readonly Font _font;
        private readonly string _outputBucket;

        private readonly HttpRequestReader _requestReader;

        public Function(ILogger<Function> logger)
        {
            _logger = logger;
            var configReader = new ConfigReader(logger);
            _outputBucket = configReader.Read("BUCKET");
            _requestReader = new HttpRequestReader(logger);

            var fontCollection = new FontCollection();
            fontCollection.Install("Arial.ttf");
            _font = fontCollection.CreateFont("Arial", 10);
        }

        public async Task HandleAsync(HttpContext context)
        {
            _logger.LogInformation("Function received request");

            try
            {
                var (bucket, file, labels) = await _requestReader.ReadCloudStorageAndLabelsData(context);

                using (var inputStream = new MemoryStream())
                {
                    var client = await StorageClient.CreateAsync();
                    await client.DownloadObjectAsync(bucket, file, inputStream);
                    _logger.LogInformation($"Downloaded '{file}' from bucket '{bucket}'");

                    using (var outputStream = new MemoryStream())
                    {
                        inputStream.Position = 0; // Reset to read
                        using (var image = Image.Load(inputStream))
                        {
                            using (var imageProcessed = image.Clone(ctx => ApplyScalingWaterMarkSimple(ctx, _font, labels, Color.DeepSkyBlue, 5)))
                            {
                                _logger.LogInformation($"Added watermark to image '{file}'");
                                imageProcessed.SaveAsJpeg(outputStream);
                            }
                        }

                        var outputObjectName = $"{Path.GetFileNameWithoutExtension(file)}-watermark.jpeg";
                        await client.UploadObjectAsync(_outputBucket, outputObjectName, "image/jpeg", outputStream);
                        _logger.LogInformation($"Uploaded '{outputObjectName}' to bucket '{_outputBucket}'");
                    }
                }
            }
            catch (Exception e)
            {
                _logger.LogError($"Error processing: " + e.Message);
                throw e;
            }
        }

        private static IImageProcessingContext ApplyScalingWaterMarkSimple(IImageProcessingContext processingContext,
            Font font,
            string text,
            Color color,
            float padding)
        {
            Size imgSize = processingContext.GetCurrentSize();

            float targetWidth = imgSize.Width - (padding * 2);
            float targetHeight = imgSize.Height - (padding * 2);

            // measure the text size
            FontRectangle size = TextMeasurer.Measure(text, new RendererOptions(font));

            //find out how much we need to scale the text to fill the space (up or down)
            float scalingFactor = Math.Min(imgSize.Width / size.Width, imgSize.Height / size.Height);

            //create a new font
            Font scaledFont = new Font(font, scalingFactor * font.Size);

            var center = new PointF(imgSize.Width / 2, imgSize.Height / 2);
            var textGraphicOptions = new TextGraphicsOptions()
            {
                TextOptions = {
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center
                }
            };
            return processingContext.DrawText(textGraphicOptions, text, scaledFont, color, center);
        }
    }
}
