# Platform Deployment (Hub Infrastructure)

This directory contains the platform team deployment for the AI/ML landing zone enterprise example. The platform team is responsible for deploying and managing the shared hub infrastructure that multiple AI/ML workloads will consume.

## Overview

This deployment creates:
- Hub virtual network with centralized networking services
- Azure Firewall for egress traffic control
- Azure Bastion for secure remote access
- DNS Private Resolver for hybrid connectivity
- Private DNS zones for Azure services
- Log Analytics workspace for centralized logging
- Jump VM for operational access

## Prerequisites

- Azure subscription with appropriate permissions
- Terraform >= 1.9
- Azure CLI authenticated with platform team credentials

## Deployment Steps

1. **Copy and configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan
   ```

4. **Apply the deployment:**
   ```bash
   terraform apply
   ```

5. **Note the outputs:** The outputs from this deployment will be needed by the workload team for their deployment.

## Important Notes

- This deployment should be completed **before** any workload deployments
- The platform team manages the lifecycle of these resources
- Workload teams will reference these resources but not modify them
- Changes to this infrastructure may impact multiple workloads

## Outputs

This deployment provides several outputs that workload teams will need:
- Hub virtual network resource ID
- Firewall private IP address
- DNS resolver inbound IP addresses
- Resource group information
- Private DNS zone details

## Resource Ownership

**Platform Team Responsibilities:**
- Hub virtual network and subnets
- Azure Firewall rules and policies
- Azure Bastion configuration
- DNS Private Resolver setup
- Private DNS zones management
- Log Analytics workspace
- Operational access (Jump VM)

**Not Included (Workload Team Responsibility):**
- AI/ML specific resources
- Application-specific networking
- Workload monitoring and alerting
- Application-specific security policies

## Security Considerations

- Jump VM access is restricted by network security groups
- Firewall rules should be configured according to organizational policies
- All diagnostic logs are sent to the centralized Log Analytics workspace
- Private DNS zones ensure secure name resolution for private endpoints

## Cost Considerations

- Azure Firewall and Bastion are always-on services with fixed costs
- Log Analytics workspace charges based on data ingestion
- Jump VM costs are based on compute size and running time
- Consider using Reserved Instances for long-running resources

## Support

For issues with platform infrastructure:
1. Check Azure Resource Health for service status
2. Review firewall logs in Log Analytics workspace
3. Contact platform team for connectivity issues
4. Escalate to Azure support for service-level issues