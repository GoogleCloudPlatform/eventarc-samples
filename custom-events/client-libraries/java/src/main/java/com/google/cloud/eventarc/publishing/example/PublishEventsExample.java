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

// [START eventarc_custom_publish_java]
package com.google.cloud.eventarc.publishing.example;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.eventarc.publishing.v1.PublishEventsRequest;
import com.google.cloud.eventarc.publishing.v1.PublishEventsResponse;
import com.google.cloud.eventarc.publishing.v1.PublisherClient;
import com.google.protobuf.Any;

import io.cloudevents.CloudEvent;
import io.cloudevents.core.provider.EventFormatProvider;
import io.cloudevents.core.v1.CloudEventBuilder;
import io.cloudevents.jackson.JsonCloudEventData;
import io.cloudevents.jackson.JsonFormat;
import io.cloudevents.protobuf.ProtobufFormat;

import java.net.URI;
import java.time.OffsetDateTime;
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

  private PublishEventsRequest GetPublishEventsRequestWithTextFormat(String channelName, CloudEvent event) {

    byte[] serializedEvent = EventFormatProvider.getInstance()
        .resolveFormat(JsonFormat.CONTENT_TYPE)
        .serialize(event);
    String textEvent = new String(serializedEvent);

    PublishEventsRequest request = PublishEventsRequest.newBuilder()
        .setChannel(channelName)
        .addTextEvents(textEvent)
        .build();

    return request;
  }

  private PublishEventsRequest GetPublishEventsRequestWithProtoFormat(String channelName, CloudEvent event) throws Exception {

    byte[] serializedEvent = EventFormatProvider.getInstance()
        .resolveFormat(ProtobufFormat.PROTO_CONTENT_TYPE)
        .serialize(event);

    io.cloudevents.v1.proto.CloudEvent protoEvent = io.cloudevents.v1.proto.CloudEvent.parseFrom(serializedEvent);
    Any wrappedEvent = Any.pack(protoEvent);

    PublishEventsRequest request = PublishEventsRequest.newBuilder()
        .setChannel(channelName)
        .addEvents(wrappedEvent)
        .build();

    return request;
  }

  public void PublishEvent(String channelName, boolean useTextEvent) throws Exception {

    CustomMessage eventData = new CustomMessage("Hello world from Java");

    LOGGER.log(Level.INFO, "Building CloudEvent");

    ObjectMapper objectMapper = new ObjectMapper();
    CloudEvent event = new CloudEventBuilder()
        .withId(UUID.randomUUID().toString())
        .withSource(URI.create("//custom/from/java"))
        // Note: Type has to match with the trigger!
        .withType("mycompany.myorg.myproject.v1.myevent")
        .withTime(OffsetDateTime.now())
        // Note: someattribute and somevalue have to match with the trigger!
        .withExtension("someattribute", "somevalue")
        .withExtension("extsourcelang", "java")
        .withData("application/json",
            JsonCloudEventData.wrap(objectMapper.valueToTree(eventData)))
        .build();


    PublishEventsRequest request = useTextEvent ?
      GetPublishEventsRequestWithTextFormat(channelName, event) :
      GetPublishEventsRequestWithProtoFormat(channelName, event);

    LOGGER.log(Level.INFO, "Publishing message to Eventarc");

    try {
      PublisherClient client = PublisherClient.create();
      PublishEventsResponse response = client.publishEvents(request);
      LOGGER.log(Level.INFO, String.format("Message published successfully.\nReceived response: %s",
          response.toString()));
    } catch (Exception ex) {
      LOGGER.log(Level.SEVERE, "An exception occurred while publishing", ex);
    }
  }

  public static void main(String[] args) throws Exception {
    String projectId = args[0];
    String region = args[1];
    String channel = args[2];
    // Controls the format of events sent to Eventarc.
    // 'true' for using text format.
    // 'false' for proto (preferred) format.
    boolean useTextEvent = args.length > 3 ? Boolean.parseBoolean(args[3]) : false;

    String channelName = "projects/" + projectId + "/locations/" + region + "/channels/" + channel;
    System.out.println("Channel: " + channelName);
    System.out.println("useTextEvent: " + useTextEvent);

    new PublishEventsExample().PublishEvent(channelName, useTextEvent);
  }
}
// [END eventarc_custom_publish_java]
