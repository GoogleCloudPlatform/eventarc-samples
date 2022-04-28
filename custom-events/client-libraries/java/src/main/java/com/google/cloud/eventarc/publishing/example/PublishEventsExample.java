/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.cloud.eventarc.publishing.example;

import com.google.cloud.eventarc.publishing.v1.PublishEventsRequest;
import com.google.cloud.eventarc.publishing.v1.PublishEventsResponse;
import com.google.cloud.eventarc.publishing.v1.PublisherClient;
import com.google.gson.Gson;
import com.google.protobuf.Any;
import com.google.protobuf.util.Timestamps;
import io.cloudevents.v1.proto.CloudEvent;
import io.cloudevents.v1.proto.CloudEvent.CloudEventAttributeValue;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

public class PublishEventsExample {
  
  static Logger LOGGER = Logger.getLogger(PublishEventsExample.class.getName());

  /**
   * CustomMessage represents a payload delivered as a content of the CloudEvent.
   */
  class CustomMessage {
    public CustomMessage(String message) {
      this.message = message;
    }
    public String message;
  }

  public void SendPublishEvent(String projectId, String region, String channel) {

    CustomMessage message = new CustomMessage("Hello world from Java client library");
    Gson gson = new Gson();

    LOGGER.log(Level.INFO, "Building CloudEvent");
    CloudEvent event = CloudEvent.newBuilder()
        .setId(UUID.randomUUID().toString())
        .setSource("//custom/from/java")
        .setType("mycompany.myorg.myproject.v1.myevent")
        // Eventarc expects 1.0 version
        .setSpecVersion("1.0")
        // Eventarc expects datacontenttype to be application/json
        .putAttributes("datacontenttype",
            CloudEventAttributeValue.newBuilder()
                .setCeString("application/json")
                .build())
        .putAttributes("time", CloudEventAttributeValue.newBuilder()
            .setCeTimestamp(Timestamps.fromMillis(System.currentTimeMillis()))
            .build())
        .putAttributes("someattribute", 
          CloudEventAttributeValue.newBuilder()
            .setCeString("somevalue")
            .build())
        .setTextData(gson.toJson(message))
        //.setTextData("{\"message\": \"Hello world from Java client library\"}")
        .build();

    Any wrappedMessage = Any.pack(event);

    LOGGER.log(Level.INFO, String.format("Building request message for channel %s", channel));
    PublishEventsRequest request = PublishEventsRequest.newBuilder()
        .setChannel("projects/" + projectId + "/locations/" + region + "/channels/" + channel)
        .addEvents(wrappedMessage)
        .build();
    LOGGER.log(Level.INFO, "Publishing message in Eventarc");
    try {
      // Create a client with credentials provided by the system.
      PublisherClient client = PublisherClient.create();
      PublishEventsResponse response = client.publishEvents(request);
      LOGGER.log(Level.INFO, String.format("Message published successfully.\nReceived response: %s",
          response.toString()));
    } catch (Exception ex) {
      LOGGER.log(Level.SEVERE, "An exception occurred while publishing", ex);
    }
  }

  public static void main(String[] args) {
    String projectId = args[0];
    String region = args[1];
    String channel = args[2];
    System.out.println("ProjectId: " + projectId + " Region: " + region + " Channel: " + channel);

    new PublishEventsExample().SendPublishEvent(projectId, region, channel);
  }
}
