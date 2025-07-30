FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Expose port (check your vite config for the port)
EXPOSE 4173

# Start the application
CMD ["npm", "run", "start"]