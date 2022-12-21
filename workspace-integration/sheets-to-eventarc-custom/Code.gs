const PROJECT_ID = "your-project-id";

const REGION = "us-central1";
const CHANNEL_NAME = "channel-sheets-custom";
const PUBLISH_URL = "https://eventarcpublishing.googleapis.com/v1/projects/" + PROJECT_ID
  + "/locations/" + REGION + "/channels/" + CHANNEL_NAME + ":publishEvents";
const EVENT_TYPE = "mycompany.myorg.myproject.v1.onopen";

function onOpenHandler(e) {
  // Uncomment for debugging
  // e = {}; e.user = "foo@bar.com";

  Logger.log("Document opened by user: " + e.user);
  publishEvent(e.user);
}

function publishEvent(user) {

  const headers = {
    // Assumes the Sheets user has the permissions to publish Eventarc events (eg. also the owner of the Google Cloud project)
    "Authorization": "Bearer " + ScriptApp.getOAuthToken()
  };

  const event = getEvent(user);
  const payload = wrapIntoEvents(event);

  const params = {
    "method": 'post',
    "contentType": 'application/json',
    "headers": headers,
    "payload": payload
  };

  Logger.log("Publishing with payload: " + payload);
  var response = UrlFetchApp.fetch(PUBLISH_URL, params);
  Logger.log("Received response code: " + response.getResponseCode() + " from URL: " + PUBLISH_URL);
}

function getEvent(user) {
  const event = {
    "@type": "type.googleapis.com/io.cloudevents.v1.CloudEvent",
    "attributes": {
      "datacontenttype": { "ceString": "application/json" },
      "time": { "ceTimestamp": new Date() }
    },
    "specVersion": "1.0",
    "id": Utilities.getUuid(),
    "source": "google_sheets",
    "textData": '{"user": "' + user + '"}',
    "type": EVENT_TYPE
  };

  Logger.log("Created an event: " + JSON.stringify(event));
  return event;
}

function wrapIntoEvents(event) {
  const events = {
    "events": [
      event
    ]
  };
  return JSON.stringify(events);
}