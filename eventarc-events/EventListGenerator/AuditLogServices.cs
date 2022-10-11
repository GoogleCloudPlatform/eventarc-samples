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
using System.Linq;

namespace EventListGenerator
{
    public class AuditLogServices
    {
        public List<AuditLogService> services {get; set;}
    }

    public class AuditLogService
    {
        // TODO: Externalize to a file if the list gets long at some point.
        private static HashSet<string> AUDITLOG_METHOD_NAMES_BLOCK_LIST = new HashSet<string> {
            "google.monitoring.v3.TimeSeriesFilterService.ParseTimeSeriesFilter"
        };

        public string serviceName { get; set; }

        private string _displayName;
        public string displayName
        {
            get {return string.IsNullOrEmpty(_displayName) ? serviceName : _displayName;}
            set {_displayName = value;}
        }

        public List<Method> methods {get; set;}

        public void WriteToStream(StreamWriter file, bool devsite)
        {
            if (devsite)
            {
                file.WriteLine($"### {displayName}\n");
                file.WriteLine("#### `serviceName`\n");
                file.WriteLine($"- `{serviceName}`\n");
                file.WriteLine("#### `methodName`\n");

                var allowedMethods = methods.Where(method => !AUDITLOG_METHOD_NAMES_BLOCK_LIST.Contains(method.methodName)).ToList();
                allowedMethods.ForEach(method => file.WriteLine($"- `{method.methodName}`"));
                file.WriteLine("");
            }
            else
            {
                file.WriteLine($"<details><summary>{displayName}</summary>");
                file.WriteLine("<p>\n");
                file.WriteLine($"`{serviceName}`\n");

                var allowedMethods = methods.Where(method => !AUDITLOG_METHOD_NAMES_BLOCK_LIST.Contains(method.methodName)).ToList();
                allowedMethods.ForEach(method => file.WriteLine($"* `{method.methodName}`"));
                file.WriteLine("\n</p>");
                file.WriteLine("</details>");
            }
        }
    }

    public class Method
    {
        public string methodName {get; set;}
    }
}