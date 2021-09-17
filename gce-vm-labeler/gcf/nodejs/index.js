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
const { google } = require("googleapis");
var compute = google.compute("v1");

exports.labelVmCreation = async (cloudevent) => {
  var data = cloudevent.data;

  // in case an event has >1 audit log
  // make sure we respond to the last event
  if (!data.operation.last) {
    console.log("Operation is not last, skipping event");
    return;
  }

  // projects/dogfood-gcf-saraford/zones/us-central1-a/instances/instance-1
  var resourceName = data.protoPayload.resourceName;
  var resourceParts = resourceName.split("/");
  var project = resourceParts[1];
  var zone = resourceParts[3];
  var instanceName = resourceParts[5];
  var username = data.protoPayload.authenticationInfo.principalEmail.split("@")[0];

  console.log(`Setting label username: ${username} to instance ${instanceName} for zone ${zone}`);

  var authClient = await google.auth.getClient({
    scopes: ["https://www.googleapis.com/auth/cloud-platform"]
  });

  // per docs: When updating or adding labels in the API,
  // you need to provide the latest labels fingerprint with your request,
  // to prevent any conflicts with other requests.
  var labelFingerprint = await getInstanceLabelFingerprint(authClient, project, zone, instanceName);

  var responseStatus = await setVmLabel(
    authClient,
    labelFingerprint,
    username,
    project,
    zone,
    instanceName
  );

  // log results of setting VM label
  console.log(JSON.stringify(responseStatus, null, 2));
};

async function getInstanceLabelFingerprint(authClient, project, zone, instanceName) {
  var request = {
    project: project,
    zone: zone,
    instance: instanceName,
    auth: authClient
  };

  var response = await compute.instances.get(request);
  var labelFingerprint = response.data.labelFingerprint;
  return labelFingerprint;
}

async function setVmLabel(authClient, labelFingerprint, username, project, zone, instanceName) {
  var request = {
    project: project,
    zone: zone,
    instance: instanceName,

    resource: {
      labels: { "creator": username },
      labelFingerprint: labelFingerprint
    },

    auth: authClient
  };

  var response = await compute.instances.setLabels(request);
  return response.statusText;
}
