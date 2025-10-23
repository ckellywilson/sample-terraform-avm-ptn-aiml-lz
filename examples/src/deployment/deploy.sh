#!/bin/bash

# Build and deploy script for AI Landing Zone Chat App

set -e

# Configuration
RESOURCE_GROUP=${RESOURCE_GROUP:-"ai-lz-rg-standalone-dev"}
CONTAINER_REGISTRY=${CONTAINER_REGISTRY:-"your-registry.azurecr.io"}
CONTAINER_APP_ENV=${CONTAINER_APP_ENV:-"ai-lz-container-env"}
APP_NAME="ai-chat-app"
IMAGE_TAG=${IMAGE_TAG:-"latest"}

echo "=== AI Landing Zone Chat App Deployment ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "Container Registry: $CONTAINER_REGISTRY"
echo "Container App Environment: $CONTAINER_APP_ENV"
echo "Image Tag: $IMAGE_TAG"

# Build and push Docker image
echo "Building Docker image..."
docker build -t $CONTAINER_REGISTRY/$APP_NAME:$IMAGE_TAG .

echo "Pushing to container registry..."
docker push $CONTAINER_REGISTRY/$APP_NAME:$IMAGE_TAG

# Deploy to Container Apps
echo "Deploying to Azure Container Apps..."
az containerapp create \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINER_APP_ENV \
  --image $CONTAINER_REGISTRY/$APP_NAME:$IMAGE_TAG \
  --target-port 8000 \
  --ingress external \
  --cpu 0.5 \
  --memory 1.0Gi \
  --min-replicas 1 \
  --max-replicas 3 \
  --env-vars \
    AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_ENDPOINT" \
    COSMOS_DB_ENDPOINT="$COSMOS_DB_ENDPOINT" \
    KEY_VAULT_URL="$KEY_VAULT_URL" \
  --secrets \
    azure-openai-key="$AZURE_OPENAI_API_KEY" \
    cosmos-db-key="$COSMOS_DB_KEY" \
    app-insights-connection="$APPLICATIONINSIGHTS_CONNECTION_STRING" \
  --secret-env-vars \
    AZURE_OPENAI_API_KEY=azure-openai-key \
    COSMOS_DB_KEY=cosmos-db-key \
    APPLICATIONINSIGHTS_CONNECTION_STRING=app-insights-connection

echo "Deployment completed!"
echo "App URL: https://$APP_NAME.$(az containerapp env show --name $CONTAINER_APP_ENV --resource-group $RESOURCE_GROUP --query properties.defaultDomain -o tsv)"