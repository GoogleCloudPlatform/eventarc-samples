(function () {
  const events = [
    // 1. store -> order.created
    {
      'source': 'store',
      'type': 'order.created',
      'datacontenttype': 'application/json',
      'time': '2026-04-15T23:07:12.727Z',
      'id': '806df26f-8988-4bb7-9aa8-3f28a062ae95',
      'env': 'demo',
      'xgooglemessageuid': '578aeff8-31de-40c1-8543-be4d2442e0c9',
      'specversion': '1.0',
      'sourceservicecolor': '#EF6C00',
      'sourceserviceinfo': 'HTTP • Web UI • Node.js',
      'data': {
        'order_id': 'ORD-5596E6',
        'shipping_address': '123 Main St, Toronto',
        'user_note': '',
        'items': [
          {
            'item_name': 'Stiletto Pump (Scarlet Red, Size 8)',
            'quantity': 515,
          },
        ],
      },
    },
    // 2. payment-processing -> log.request.received
    {
      'source': 'payment-processing',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'xgooglemessageuid': 'ecedb1d0-91b5-4c37-80db-a960fda97e37',
      'specversion': '1.0',
      'env': 'demo',
      'sourceservicecolor': '#FF5722',
      'sourceserviceinfo': 'MCP • ADK • Python',
      'id': '187f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:07:13.762Z',
      'data': {
        'original_event_id': '806df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'store',
        'raw_request':
          'POST / HTTP/1.1\nhost: payment-processing-xyow2zkm4q-uc.a.run.app\naccept: application/json\ncontent-type: application/json\ncontent-length: 359\nuser-agent: Google-mts-convoy\nce-specversion: 1.0\nce-type: order.created\nce-sourceservicecolor: #EF6C00\nce-time: 2026-04-16T03:07:12.727731Z\nce-xgooglemessageuid: 578aeff8-31de-40c1-8543-be4d2442e0c9\nce-env: demo\nce-source: store\nce-id: 806df26f-8988-4bb7-9aa8-3f28a062ae95\n\n{\n  "id": "806df26f-8988-4bb7-9aa8-3f28a062ae95",\n  "method": "tools/call",\n  "jsonrpc": "2.0",\n  "params": {\n    "name": "run_agent",\n    "arguments": {\n      "prompt": "Process payment for the following order: {\\"shipping_address\\":\\"123 Main St, Toronto\\",\\"user_note\\":\\"\\",\\"items\\":[{\\"quantity\\":515,\\"item_name\\":\\"Stiletto Pump (Scarlet Red, Size 8)\\"}],\\"order_id\\":\\"ORD-5596E6\\"}"\n    }\n  }\n}',
      },
    },
    // 3. payment-processing -> order.paid
    {
      'source': 'payment-processing',
      'type': 'order.paid',
      'datacontenttype': 'application/json',
      'id': '6eff9622-4f26-45e0-808b-678c984d33e7',
      'time': '2026-04-15T23:07:14.973Z',
      'xgooglemessageuid': '574e5784-b109-4c5f-92db-a1dba82743fc',
      'specversion': '1.0',
      'env': 'demo',
      'sourceservicecolor': '#FF5722',
      'data': {
        'status': 'success',
        'order_id': 'ORD-5596E6',
        'shipping_address': '123 Main St, Toronto',
        'user_note': '',
        'items': [
          {
            'item_name': 'Stiletto Pump (Scarlet Red, Size 8)',
            'quantity': 515,
          },
        ],
      },
    },
    // 4. fulfillment-planning -> log.request.received
    {
      'source': 'fulfillment-planning',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'sourceserviceinfo': 'A2A • ADK • Python',
      'xgooglemessageuid': '8c108022-ceea-48c5-a1af-43f138febba0',
      'specversion': '1.0',
      'id': 'c8585fbc-b4bb-4ec5-8e8c-52f7b3f4dab1',
      'env': 'demo',
      'time': '2026-04-15T23:07:15.500Z',
      'data': {
        'original_event_id': '6eff9622-4f26-45e0-808b-678c984d33e7',
        'original_event_source': 'payment-processing',
        'raw_request':
          'POST / HTTP/1.1\nhost: fulfillment-planning-xyow2zkm4q-uc.a.run.app\ncontent-type: application/json\na2a-version: 1.0\ncontent-length: 448\nuser-agent: Google-mts-convoy\nce-source: payment-processing\nce-env: demo\nce-type: order.paid\nce-sourceservicecolor: #FF5722\nce-xgooglemessageuid: 578aeff8-31de-40c1-8543-be4d2442e0c9\nce-id: 6eff9622-4f26-45e0-808b-678c984d33e7\nce-specversion: 1.0\nce-time: 2026-04-16T03:07:12.727731Z\n\n{\n  "id": "6eff9622-4f26-45e0-808b-678c984d33e7",\n  "jsonrpc": "2.0",\n  "method": "message/send",\n  "params": {\n    "message": {\n      "parts": [\n        {\n          "text": "\\nCreate a fulfillment plan for the following order:\\n------------------\\nOrder ID: ORD-5596E6\\nAddress: 123 Main St, Toronto\\nItems: [{\\"quantity\\":515,\\"item_name\\":\\"Stiletto Pump (Scarlet Red, Size 8)\\"}]\\nNotes: \\n"\n        }\n      ],\n      "role": "user",\n      "messageId": "6eff9622-4f26-45e0-808b-678c984d33e7"\n    },\n    "configuration": {\n      "blocking": true\n    }\n  }\n}',
      },
    },
    // 5. fulfillment-planning -> fulfillment.plan.created
    {
      'source': 'fulfillment-planning',
      'type': 'fulfillment.plan.created',
      'datacontenttype': 'application/json',
      'sourceserviceinfo': 'A2A • ADK • Python',
      'has_third_party': true,
      'xgooglemessageuid': 'c0893d37-7b80-4ed3-a4648789bb03832e',
      'has_internal': true,
      'specversion': '1.0',
      'env': 'demo',
      'id': 'dd3d0841-eba6-4607-85aa-a69941a7967d',
      'time': '2026-04-15T23:07:16.797Z',
      'data': {
        'order_id': 'ORD-5596E6',
        'shipment_plan': [
          {
            'item_name': 'Stiletto Pump (Scarlet Red, Size 8)',
            'type': 'internal',
            'quantity': 200,
          },
          {
            'item_name': 'Stiletto Pump (Scarlet Red, Size 8)',
            'quantity': 315,
            'type': 'third_party',
          },
        ],
        'total_cost': 51535,
        'shipping_address': '123 Main St, Toronto',
      },
    },
    // 6. internal-shipment -> log.request.received
    {
      'source': 'internal-shipment',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'sourceservicecolor': '#009688',
      'sourceserviceinfo': 'LangChain • ADK • Python',
      'time': '2026-04-15T23:07:21.797Z',
      'id': '80f897ea-2980-464c-9053-78b21961418c',
      'env': 'demo',
      'xgooglemessageuid': '17a92915-9cd3-4012-8ed0-ea489b935b3f',
      'specversion': '1.0',
      'data': {
        'original_event_id': 'dd3d0841-eba6-4607-85aa-a69941a7967d',
        'original_event_source': 'fulfillment-planning',
        'raw_request':
          'POST / HTTP/1.1\nhost: internal-shipment-xyow2zkm4q-uc.a.run.app\ncontent-type: application/json\na2a-version: 1.0\ncontent-length: 477\nuser-agent: Google-mts-convoy\nce-source: fulfillment-planning\nce-has_internal: true\nce-specversion: 1.0\nce-env: demo\nce-id: dd3d0841-eba6-4607-85aa-a69941a7967d\nce-has_third_party: true\nce-type: fulfillment.plan.created\nce-xgooglemessageuid: c0893d37-7b80-4ed3-a4648789bb03832e\nce-time: 2026-04-16T03:07:16.797919Z\n\n{\n  "params": {\n    "configuration": {\n      "blocking": true\n    },\n    "message": {\n      "messageId": "dd3d0841-eba6-4607-85aa-a69941a7967d",\n      "parts": [\n        {\n          "text": "Process this internal shipment plan: {\\"total_cost\\":51535,\\"order_id\\":\\"ORD-5596E6\\",\\"shipment_plan\\":[{\\"item_name\\":\\"Stiletto Pump (Scarlet Red, Size 8)\\",\\"quantity\\":200,\\"type\\":\\"internal\\"}],\\"shipping_address\\":\\"123 Main St, Toronto\\"}"\n        }\n      ],\n      "role": "user"\n    }\n  },\n  "jsonrpc": "2.0",\n  "id": "dd3d0841-eba6-4607-85aa-a69941a7967d",\n  "method": "message/send"\n}',
      },
    },
    // 7. internal-shipment -> shipment.internal.processed
    {
      'source': 'internal-shipment',
      'type': 'shipment.internal.processed',
      'datacontenttype': 'application/json',
      'sourceservicecolor': '#009688',
      'sourceserviceinfo': 'LangChain • ADK • Python',
      'specversion': '1.0',
      'xgooglemessageuid': 'a62a1c79-dd04-4887-a92f-fec8407a511e',
      'env': 'demo',
      'id': 'd457dfce-f397-48d2-97f7-650a02a4743a',
      'time': '2026-04-15T23:07:23.371Z',
      'data': {
        'status': 'Picking sequence generated for internal warehouse.',
        'order_id': 'ORD-5596E6',
      },
    },
    // 8. third-party-shipment -> log.request.received
    {
      'source': 'third-party-shipment',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'sourceservicecolor': '#607D8B',
      'sourceserviceinfo': 'External • REST',
      'specversion': '1.0',
      'xgooglemessageuid': '882d2bd2-59df-4467-a8c5-4f5a33d2a7f5',
      'time': '2026-04-15T23:07:38.218Z',
      'id': 'f721a759-51fe-47ef-bf1e-c0e104f33284',
      'data': {
        'original_event_id': 'dd3d0841-eba6-4607-85aa-a69941a7967d',
        'original_event_source': 'fulfillment-planning',
        'raw_request':
          'POST / HTTP/1.1\nhost: third-party-shipment-cqnlbujiuq-uc.a.run.app\ncontent-length: 176\nuser-agent: Google-mts-convoy\nce-time: 2026-04-16T03:07:16.797919Z\nce-has_internal: true\nce-type: fulfillment.plan.created\nce-xgooglemessageuid: c0893d37-7b80-4ed3-a4648789bb03832e\nce-has_third_party: true\nce-env: demo\nce-specversion: 1.0\nce-source: fulfillment-planning\nce-id: dd3d0841-eba6-4607-85aa-a69941a7967d\ncontent-type: application/json\n\n{\n  "carrier_request": {\n    "reference_id": "ORD-5596E6",\n    "consignment": {\n      "address": "123 Main St, Toronto",\n      "parcels": [\n        {\n          "count": 315,\n          "description": "Stiletto Pump (Scarlet Red, Size 8)"\n        }\n      ]\n    }\n  }\n}',
      },
    },
    // 9. third-party-shipment -> shipment.third_party.processed
    {
      'source': 'third-party-shipment',
      'type': 'shipment.third_party.processed',
      'datacontenttype': 'application/json',
      'id': '906df26f-8988-4bb7-9aa8-3f28a062ae95',
      'time': '2026-04-15T23:07:40.123Z',
      'data': {
        'status': 'Third party carrier assigned.',
        'order_id': 'ORD-5596E6',
      },
    },
    // 10. notification-service -> log.request.received (consuming shipment.third_party.processed)
    {
      'source': 'notification-service',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '917f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:07:41.234Z',
      'data': {
        'original_event_id': '906df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'third-party-shipment',
      },
    },
    // 11. internal-shipment -> inventory.updated
    {
      'source': 'internal-shipment',
      'type': 'inventory.updated',
      'datacontenttype': 'application/json',
      'sourceservicecolor': '#009688',
      'sourceserviceinfo': 'LangChain • ADK • Python',
      'id': '926df26f-8988-4bb7-9aa8-3f28a062ae95',
      'time': '2026-04-15T23:07:42.345Z',
      'data': {
        'order_id': 'ORD-5596E6',
        'items': [
          {'item_name': 'Stiletto Pump (Scarlet Red, Size 8)', 'quantity': 200},
        ],
      },
    },
    // 12. inventory-service -> log.request.received (consuming inventory.updated)
    {
      'source': 'inventory-service',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '937f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:07:43.456Z',
      'data': {
        'original_event_id': '926df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'internal-shipment',
      },
    },
    // 13. internal-shipment -> shipment.out_for_delivery
    {
      'source': 'internal-shipment',
      'type': 'shipment.out_for_delivery',
      'datacontenttype': 'application/json',
      'sourceservicecolor': '#009688',
      'sourceserviceinfo': 'LangChain • ADK • Python',
      'id': '946df26f-8988-4bb7-9aa8-3f28a062ae95',
      'time': '2026-04-15T23:07:45.567Z',
      'data': {'order_id': 'ORD-5596E6', 'carrier': 'DHL'},
    },
    // 14. notification-service -> log.request.received (consuming shipment.out_for_delivery)
    {
      'source': 'notification-service',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '957f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:07:46.678Z',
      'data': {
        'original_event_id': '946df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'internal-shipment',
      },
    },
    // 15. notification-service -> sms.send (for out for delivery)
    {
      'source': 'notification-service',
      'type': 'sms.send',
      'datacontenttype': 'application/json',
      'id': '966df26f-8988-4bb7-9aa8-3f28a062ae95',
      'time': '2026-04-15T23:07:47.789Z',
      'data': {
        'order_id': 'ORD-5596E6',
        'message': 'Your order is out for delivery!',
      },
    },
    // 16. sms-service -> log.request.received (consuming sms.send)
    {
      'source': 'sms-service',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '977f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:07:48.890Z',
      'data': {
        'original_event_id': '966df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'notification-service',
      },
    },
    // 17. internal-shipment -> shipment.delivered
    {
      'source': 'internal-shipment',
      'type': 'shipment.delivered',
      'datacontenttype': 'application/json',
      'sourceservicecolor': '#009688',
      'sourceserviceinfo': 'LangChain • ADK • Python',
      'id': '986df26f-8988-4bb7-9aa8-3f28a062ae95',
      'time': '2026-04-15T23:07:50.001Z',
      'data': {'order_id': 'ORD-5596E6', 'signature': 'John Doe'},
    },
    // 18. notification-service -> log.request.received (consuming shipment.delivered)
    {
      'source': 'notification-service',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '997f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:07:51.112Z',
      'data': {
        'original_event_id': '986df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'internal-shipment',
      },
    },
    // 19. analytics-service -> log.request.received (consuming shipment.delivered)
    {
      'source': 'analytics-service',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '1007f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:07:52.223Z',
      'data': {
        'original_event_id': '986df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'internal-shipment',
      },
    },
    // 20. notification-service -> email.send (for delivery confirmation)
    {
      'source': 'notification-service',
      'type': 'email.send',
      'datacontenttype': 'application/json',
      'id': '1016df26f-8988-4bb7-9aa8-3f28a062ae95',
      'time': '2026-04-15T23:07:53.334Z',
      'data': {
        'order_id': 'ORD-5596E6',
        'message': 'Your order has been delivered!',
      },
    },
    // 21. email-service -> log.request.received (consuming email.send)
    {
      'source': 'email-service',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '1027f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:07:54.445Z',
      'data': {
        'original_event_id': '1016df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'notification-service',
      },
    },
    // 22. notification-service -> customer.survey.sent
    {
      'source': 'notification-service',
      'type': 'customer.survey.sent',
      'datacontenttype': 'application/json',
      'id': '1036df26f-8988-4bb7-9aa8-3f28a062ae95',
      'time': '2026-04-15T23:07:55.556Z',
      'data': {
        'order_id': 'ORD-5596E6',
        'survey_url': 'http://survey.com/ORD-5596E6',
      },
    },
    // 23. survey-service -> log.request.received (consuming customer.survey.sent)
    {
      'source': 'survey-service',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '1047f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:07:56.667Z',
      'data': {
        'original_event_id': '1036df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'notification-service',
      },
    },
    // 24. analytics-service -> analytics.order.completed
    {
      'source': 'analytics-service',
      'type': 'analytics.order.completed',
      'datacontenttype': 'application/json',
      'id': '1056df26f-8988-4bb7-9aa8-3f28a062ae95',
      'time': '2026-04-15T23:07:57.778Z',
      'data': {'order_id': 'ORD-5596E6', 'total_time_seconds': 45},
    },
    // 25. store -> order.created (Second Order)
    {
      'source': 'store',
      'type': 'order.created',
      'datacontenttype': 'application/json',
      'time': '2026-04-15T23:08:00.000Z',
      'id': '200df26f-8988-4bb7-9aa8-3f28a062ae95',
      'data': {
        'order_id': 'ORD-6666E6',
        'shipping_address': '456 Oak St, Vancouver',
        'items': [{'item_name': 'Running Shoes', 'quantity': 2}],
      },
    },
    // 26. payment-processing -> log.request.received (consuming second order)
    {
      'source': 'payment-processing',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '2017f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:08:01.000Z',
      'data': {
        'original_event_id': '200df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'store',
      },
    },
    // 27. order.paid (Second Order)
    {
      'source': 'payment-processing',
      'type': 'order.paid',
      'datacontenttype': 'application/json',
      'id': '2026df26f-8988-4bb7-9aa8-3f28a062ae95',
      'time': '2026-04-15T23:08:02.000Z',
      'data': {'status': 'success', 'order_id': 'ORD-6666E6'},
    },
    // 28. notification-service -> log.request.received (consuming second order.paid)
    {
      'source': 'notification-service',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '2037f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:08:03.000Z',
      'data': {
        'original_event_id': '2026df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'payment-processing',
      },
    },
    // 29. email.send (for second order confirmation)
    {
      'source': 'notification-service',
      'type': 'email.send',
      'datacontenttype': 'application/json',
      'id': '2046df26f-8988-4bb7-9aa8-3f28a062ae95',
      'time': '2026-04-15T23:08:04.000Z',
      'data': {
        'order_id': 'ORD-6666E6',
        'message': 'Your second order is confirmed!',
      },
    },
    // 30. email-service -> log.request.received (consuming email.send)
    {
      'source': 'email-service',
      'type': 'log.request.received',
      'datacontenttype': 'application/json',
      'id': '2057f2f51-e2f7-49ce-a437-b4e6c43b5dc8',
      'time': '2026-04-15T23:08:05.000Z',
      'data': {
        'original_event_id': '2046df26f-8988-4bb7-9aa8-3f28a062ae95',
        'original_event_source': 'notification-service',
      },
    },
  ];

  function runSimulation() {
    console.log('Starting event simulation...');
    let index = 0;

    function sendNext() {
      if (index >= events.length) {
        console.log('Simulation finished.');
        return;
      }

      const event = events[index];
      console.log('Simulating event:', event.type);

      // Call global functions from index.html
      if (typeof processCloudEventForGraph === 'function') {
        processCloudEventForGraph(event);
      }
      if (typeof appendLogEvent === 'function') {
        appendLogEvent(event);
      }

      index++;
      const interval = Math.random() * (2000 - 500) + 500; // 0.5s to 2s
      setTimeout(sendNext, interval);
    }

    sendNext();
  }

  // Fetch config to see if we should run
  fetch('/config')
    .then((response) => response.json())
    .then((config) => {
      if (config.enableSimulation) {
        runSimulation();
      } else {
        console.log('Simulation disabled by config.');
      }
    })
    .catch((error) => {
      console.error('Failed to fetch simulation config:', error);
    });
})();
