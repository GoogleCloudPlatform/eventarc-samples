# Use the official lightweight Node.js 20 image
FROM node:20-alpine

# Create and change to the app directory
WORKDIR /usr/src/app

# Copy application dependency manifests
COPY package*.json ./

# Install production dependencies
RUN npm install --only=production

# Copy local code to the container image
COPY . ./

# Run the web service on container startup
CMD [ "npm", "start" ]
