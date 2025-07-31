FROM node:20-alpine
WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

EXPOSE 4173
CMD ["npm", "run", "start"]