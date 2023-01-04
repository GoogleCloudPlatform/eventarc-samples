const PROJECT_ID = "your-project-id";

const REGION = "us-central1";
const CHANNEL_NAME = "channel-sheets-custom";
const PUBLISH_URL = "https://eventarcpublishing.googleapis.com/v1/projects/" + PROJECT_ID
  + "/locations/" + REGION + "/channels/" + CHANNEL_NAME + ":publishEvents";
const EVENT_TYPE = "mycompany.myorg.myproject.v1.onedit";

function onEditHandler(editEvent) {
  // Uncomment for debugging
  //e = {}; e.user = "foo@bar.com";

  Logger.log("Document edited by user: " + editEvent.user);
  Logger.log(editEvent.range.getA1Notation());
  Logger.log(editEvent.oldValue);
  Logger.log(editEvent.value);

  publishEvent(editEvent);
}

function publishEvent(editEvent) {

  const headers = {
    // Assumes the Sheets user has the 'roles/eventarc.publisher' role to
    // publish Eventarc events (eg. the owner of the Google Cloud project)
    "Authorization": "Bearer " + ScriptApp.getOAuthToken()
  };

  const event = getEvent(editEvent);
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

function getEvent(editEvent) {
  const event = {
    "@type": "type.googleapis.com/io.cloudevents.v1.CloudEvent",
    "attributes": {
      "datacontenttype": { "ceString": "application/json" },
      "time": { "ceTimestamp": new Date() }
    },
    "specVersion": "1.0",
    "id": Utilities.getUuid(),
    "source": "google_sheets",
    "textData": '{"user": "' + editEvent.user + '", "range": "' + editEvent.range.getA1Notation() 
        + '", "oldValue": "' + editEvent.oldValue + '", "newValue": "' + editEvent.value + '"}',
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