# AI Landing Zone Chat Application

A unified chat application that works across all AI Landing Zone deployment scenarios (default, standalone, enterprise).

## Features

- **AI Chat Interface**: Simple web UI for conversing with deployed AI models
- **Chat History**: Persistent storage of conversations using Cosmos DB
- **Network Connectivity Testing**: Validates private endpoint resolution and connectivity
- **Application Insights**: Full telemetry and monitoring integration
- **Multi-Deployment Support**: Works with default, standalone, and enterprise scenarios

## Architecture

```
├── app/
│   ├── main.py              # FastAPI application entry point
│   ├── config.py            # Configuration and environment variables
│   ├── models/              # Data models
│   ├── services/            # Business logic services
│   ├── routers/             # API route handlers
│   └── static/              # Frontend assets
├── requirements.txt         # Python dependencies
├── Dockerfile              # Container image definition
├── docker-compose.yml      # Local development setup
└── deployment/             # Deployment configurations
```

## Network Testing

The application tests connectivity to these private endpoints:
- AI Foundry/OpenAI endpoints
- Cosmos DB
- Storage Account
- Key Vault
- Container Registry
- Application Configuration
- API Management (if deployed)

## Deployment Options

### Container Apps (Recommended)
Deploy to Azure Container Apps environment in your landing zone.

### Docker Compose (Development)
```bash
docker-compose up
```

### Local Development
```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Configuration

Set these environment variables or use Azure Key Vault:
- `AZURE_OPENAI_ENDPOINT`
- `AZURE_OPENAI_API_KEY`
- `COSMOS_DB_ENDPOINT`
- `COSMOS_DB_KEY`
- `APPLICATIONINSIGHTS_CONNECTION_STRING`

## Usage

1. Access the web interface at `http://localhost:8000`
2. View network connectivity status on the dashboard
3. Start chatting with the AI model
4. Monitor telemetry in Application Insights