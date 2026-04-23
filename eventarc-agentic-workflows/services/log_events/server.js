const express = require('express');
const app = express();

// Parse incoming JSON payloads from Eventarc
app.use(express.json());

// Parse incoming text/plain payloads
app.use(express.text());

// Serve static files (like simulation.js)
app.use(express.static(__dirname));

// Store connected browser clients
let clients = [];

// 1. Serve the Unified UI Dashboard
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/index.html');
});

// Expose configuration to the frontend
app.get('/config', (req, res) => {
  res.json({enableSimulation: process.env.ENABLE_SIMULATION === 'true'});
});

// 2. The SSE stream endpoint for the frontend
app.get('/stream', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  clients.push(res);
  console.log('New browser client connected.');

  // Remove client when they close the browser tab
  req.on('close', () => {
    clients = clients.filter((client) => client !== res);
  });
});

// 3. The Eventarc receiver endpoint
app.post('/', (req, res) => {
  // Start with the business payload
  const cloudEvent = {
    data: req.body,
  };

  // Capture the standard HTTP Content-Type header
  // In CloudEvents binary mode, this maps to the 'datacontenttype' attribute
  if (req.headers['content-type']) {
    cloudEvent['datacontenttype'] = req.headers['content-type'];
  }

  // Dynamically extract ALL 'ce-' headers
  for (const [key, value] of Object.entries(req.headers)) {
    if (key.toLowerCase().startsWith('ce-')) {
      // Strip the 'ce-' prefix (length 3) to get the true attribute name
      const attributeName = key.substring(3);
      cloudEvent[attributeName] = Buffer.from(value, 'latin1').toString('utf8');
    }
  }

  console.log(
    'Received event from Eventarc:',
    cloudEvent.type || 'unknown type',
  );

  // Push the fully dynamic event to all connected browser tabs
  clients.forEach((client) => {
    client.write(`data: ${JSON.stringify(cloudEvent)}\n\n`);
  });

  res.status(200).send('Event received and broadcasted.');
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Observability service listening on port ${PORT}`);
});
