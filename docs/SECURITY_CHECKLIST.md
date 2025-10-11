# Security Checklist

## ✅ Credentials Management

### What's Secure
- [x] **Service Principal Creation Script**: No hardcoded credentials
- [x] **Authentication Setup Script**: Loads from .env or environment variables
- [x] **Template File**: `.env.template` contains only placeholder values
- [x] **GitIgnore**: `.env` file is properly excluded from version control
- [x] **Documentation**: No real credentials exposed in docs

### What to Never Commit
- [ ] `.env` file with real credentials
- [ ] Service principal client secrets
- [ ] Any Azure subscription IDs in scripts
- [ ] Tenant IDs in configuration files
- [ ] Storage account keys (we use Azure AD instead)

## 🔒 Authentication Security

### Service Principal Security
- [x] **Least Privilege**: Only necessary roles assigned
- [x] **Scope Limitation**: Roles scoped to specific subscription
- [x] **Azure AD Authentication**: No storage keys used
- [x] **Role Separation**: Different roles for different purposes
  - Contributor: Resource management
  - User Access Administrator: Role assignment management
  - Storage Blob Data Contributor: State file access

### Local Development Security
- [x] **Environment Variables**: Credentials loaded from environment
- [x] **Template System**: Safe templates for credential setup
- [x] **Clear Instructions**: Users know what to keep secure

## 🛡️ Infrastructure Security

### Storage Account Security
- [x] **Azure AD Only**: Storage key access disabled
- [x] **HTTPS Only**: All traffic encrypted in transit
- [x] **Private Containers**: No public blob access
- [x] **Encryption at Rest**: Microsoft-managed encryption enabled
- [x] **Network Security**: Default deny with Azure services bypass

### Backend Security
- [x] **Environment Isolation**: Separate storage per environment
- [x] **State File Encryption**: Terraform state encrypted in Azure
- [x] **Access Control**: Proper RBAC on storage accounts
- [x] **Audit Trail**: All access logged in Azure

## 🔍 Security Verification Commands

### Check Authentication
```bash
# Verify you're using service principal (not user account)
az account show --query user.type -o tsv
# Should return: servicePrincipal

# Check current subscription
az account show --query name -o tsv
```

### Verify Storage Security
```bash
# Check storage account security settings
az storage account show --name <storage-account> --resource-group <rg> --query allowSharedKeyAccess
# Should return: false

# Verify container access
az storage container show --name tfstate --account-name <storage-account> --auth-mode login
# Should work without errors (using Azure AD)
```

### Verify Role Assignments
```bash
# Check service principal roles
az role assignment list --assignee <client-id> --output table
# Should show: Contributor and User Access Administrator
```

## 🚨 Security Incident Response

### If Credentials Are Compromised
1. **Immediate Actions**:
   ```bash
   # Revoke the compromised service principal
   az ad sp delete --id <client-id>
   
   # Create new service principal
   ./scripts/create-service-principal.sh <subscription-id>
   
   # Update .env file with new credentials
   ```

2. **Audit Actions**:
   - Check Azure Activity Log for unauthorized actions
   - Review Terraform state for unexpected changes
   - Verify all resources are in expected state

### If .env File Is Accidentally Committed
1. **Immediate Actions**:
   ```bash
   # Remove from git history
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch .env' --prune-empty --tag-name-filter cat -- --all
   
   # Force push (WARNING: Destructive)
   git push origin --force --all
   ```

2. **Follow-up Actions**:
   - Rotate all credentials in the committed .env file
   - Notify team members to pull latest changes
   - Update documentation if needed

## 📋 Pre-Deployment Security Review

Before deploying to production:

- [ ] No credentials in any committed files
- [ ] All service principals have minimal required permissions  
- [ ] Storage accounts use Azure AD authentication only
- [ ] Network security rules are properly configured
- [ ] Audit logging is enabled on all resources
- [ ] Backup and disaster recovery procedures are documented
- [ ] Team members trained on security procedures

## 🔄 Regular Security Maintenance

### Monthly Tasks
- [ ] Rotate service principal client secrets
- [ ] Review and audit role assignments
- [ ] Check for unused service principals
- [ ] Verify storage account security settings

### Quarterly Tasks  
- [ ] Full security assessment of infrastructure
- [ ] Update security documentation
- [ ] Review and test incident response procedures
- [ ] Security training for team members

This checklist ensures that credentials and infrastructure remain secure throughout the development and deployment lifecycle.

## ❓ Frequently Asked Questions

### Q: Do I need to create a Managed Identity?
**A: No!** 
- For **local development**: Create a Service Principal (use `./scripts/create-service-principal.sh`)
- For **CI/CD pipeline**: Managed Identity is automatically provided by Azure DevOps/GitHub Actions

### Q: What's the difference between Service Principal and Managed Identity?
**A: Both do the same thing, but:**
- **Service Principal**: Works everywhere, you manage credentials
- **Managed Identity**: Only works on Azure resources, Azure manages credentials automatically

### Q: Why not use Managed Identity for local development?
**A: Managed Identity only works on Azure resources.** Your local machine isn't an Azure resource, so it can't use Managed Identity.

### Q: Will my CI/CD pipeline use the same credentials as local development?
**A: No!**
- **Local**: Uses your Service Principal credentials
- **CI/CD**: Uses Managed Identity (automatically provided)
- **Both authenticate the same way** (Azure AD), so your Terraform code works identically