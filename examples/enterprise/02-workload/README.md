# Workload Deployment (AI/ML Landing Zone)

This directory contains the workload team deployment for the AI/ML landing zone enterprise example. The workload team is responsible for deploying and managing their AI/ML resources that consume the shared platform infrastructure.

## Overview

This deployment creates:
- Spoke virtual network connected to platform hub
- Azure AI Foundry with AI projects and model deployments
- Azure Cognitive Services and AI Search
- Storage accounts for AI/ML data and models
- Key Vault for secrets management
- Cosmos DB for AI project metadata
- Application Gateway for web traffic
- Container App Environment for microservices
- Private endpoints for secure connectivity

## Prerequisites

- Platform deployment must be completed first (`../01-platform`)
- Azure subscription with appropriate permissions (may be different from platform subscription)
- Terraform >= 1.9
- Azure CLI authenticated with workload team credentials

## Deployment Steps

1. **Ensure platform is deployed:** The platform hub must be deployed and available before proceeding.

2. **Copy and configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Configure hub connection:** Choose one of two approaches:
   - **Remote State (Recommended):** Reference platform deployment outputs
   - **Data Sources:** Query existing hub resources directly

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```

5. **Plan the deployment:**
   ```bash
   terraform plan
   ```

6. **Apply the deployment:**
   ```bash
   terraform apply
   ```

## Hub Connection Options

### Option 1: Remote State (Recommended)
```hcl
use_remote_state = true
remote_state_backend = "local"
remote_state_config = {
  path = "../01-platform/terraform.tfstate"
}
```

### Option 2: Data Sources
```hcl
use_remote_state = false
hub_virtual_network_name = "vnet-hub-production"
hub_resource_group_name = "rg-platform-hub-production"
# ... other hub resource references
```

## Architecture Decisions

### Network Design
- **Spoke VNet:** Connected to platform hub via VNet peering
- **Address Space:** Must not overlap with hub or other spokes
- **DNS:** Uses platform-provided DNS resolver
- **Egress:** All outbound traffic routed through platform firewall

### Security Design
- **Private Endpoints:** All PaaS services accessed privately
- **Network Isolation:** Subnets segmented with NSGs
- **Access Control:** RBAC applied at resource and subscription level
- **Secrets Management:** Centralized in Key Vault with private access

### AI/ML Design
- **AI Foundry:** Central platform for AI model management
- **Model Deployment:** Dedicated AI service instances
- **Data Storage:** Separated by purpose and sensitivity
- **Compute:** Container Apps for scalable AI workloads

## Resource Ownership

**Workload Team Responsibilities:**
- AI/ML services and models
- Application code and configuration
- Workload-specific monitoring and alerting  
- Data management and governance
- Application security policies
- Cost optimization for workload resources

**Platform Team Dependencies:**
- Hub virtual network and connectivity
- DNS resolution and private zones
- Firewall rules and network security
- Bastion access for operations
- Centralized logging infrastructure

## Monitoring and Operations

### Application Insights
- Application performance monitoring
- Custom metrics and dashboards
- Alert rules for workload health

### Log Analytics
- Centralized logging for all workload resources
- Correlation with platform infrastructure logs
- Security and compliance reporting

### Health Monitoring
- Resource health checks
- Dependency monitoring
- Automated alert escalation

## Security Considerations

### Network Security
- All PaaS services use private endpoints
- NSG rules restrict traffic between subnets
- No direct internet access (via platform firewall)
- VNet injection for container services

### Identity and Access
- Managed identity for service-to-service authentication
- RBAC roles assigned per principle of least privilege
- Key Vault for secret and certificate management
- Azure AD integration for user access

### Data Protection
- Encryption at rest and in transit
- Customer-managed keys (optional)
- Data classification and labeling
- Backup and disaster recovery

## Cost Optimization

### Resource Management
- Right-sizing AI compute resources
- Auto-scaling for container workloads
- Reserved instances for predictable workloads
- Spot instances for development/testing

### Monitoring and Control
- Cost alerts and budgets
- Resource tagging for chargeback
- Automated resource cleanup
- Regular cost reviews

## Troubleshooting

### Common Issues
1. **DNS Resolution:** Verify hub DNS resolver configuration
2. **Network Connectivity:** Check firewall rules and NSG settings
3. **Private Endpoints:** Ensure private DNS zones are linked
4. **Resource Deployment:** Validate RBAC permissions and quotas

### Support Escalation
1. **Application Issues:** Workload team responsibility
2. **Network Connectivity:** Escalate to platform team
3. **Azure Service Issues:** Contact Azure support
4. **Security Incidents:** Follow organizational security procedures

## Development Workflow

### Environment Management
- Use separate subscriptions for dev/test/prod
- Maintain consistency across environments  
- Automated deployment pipelines
- Infrastructure as Code best practices

### Testing Strategy
- Unit tests for infrastructure code
- Integration tests with platform dependencies
- Performance testing for AI workloads
- Security scanning and compliance checks