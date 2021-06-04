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

namespace EventListGenerator
{
    public class PubSubServices
    {
        public List<PubSubService> services {get; set;}
    }

    public class PubSubService
    {
        public string description {get; set;}
        public string serviceName { get; set; }

        public string displayName {get; set;}

        public string url {get; set;}

        public int priority {get; set;}
    }
}