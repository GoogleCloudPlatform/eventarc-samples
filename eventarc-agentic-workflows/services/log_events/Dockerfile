# Use the official lightweight Node.js 22 image
FROM node:22-alpine

# Create and change to the app directory
WORKDIR /usr/src/app

# Copy application dependency manifests
COPY services/log_events/package*.json ./

# Install production dependencies
RUN npm install --only=production

# Copy local code to the container image
COPY services/log_events ./

# Run the web service on container startup
CMD [ "npm", "start" ]
