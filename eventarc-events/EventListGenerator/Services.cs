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
using System.Collections.Generic;
using System.IO;

namespace EventListGenerator
{
    public class Services
    {
        public List<Service> direct {get; set;}

        public List<Service> thirdParty {get; set;}
    }

    public class Service
    {
        public string displayName {get; set;}

        public List<string> events {get; set;}

        public bool preview {get; set;}

        public void WriteToStream(StreamWriter file, bool devsite)
        {
            var displayNameWithPreview = preview ? displayName + " (preview)" : displayName;
            if (devsite)
            {
                file.WriteLine($"\n### {displayNameWithPreview}\n");
                events.ForEach(current => file.WriteLine($"- `{current}`"));
            }
            else
            {
                file.WriteLine($"<details><summary>{displayNameWithPreview}</summary>");
                file.WriteLine("<p>\n");
                events.ForEach(current => file.WriteLine($"* `{current}`"));
                file.WriteLine("\n</p>");
                file.WriteLine("</details>");
            }
        }
    }
}