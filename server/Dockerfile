FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY index.mjs ./

# Build the deployment package
RUN npm run build

# The lambda function is now packaged in ../.terraform/lambda_function_payload.zip
# This container is mainly for building, not running the lambda
CMD ["echo", "Lambda function built and packaged"]