# Contributing to Azure AI/ML Landing Zone

## Development Workflow

### Branch Strategy
- `main` - Production deployments
- `develop` - Development deployments
- Feature branches - Individual features/fixes

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Update Terraform configurations
   - Test locally when possible
   - Follow Terraform formatting standards

3. **Format and validate**
   ```bash
   ./scripts/format-and-validate.sh
   ```

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: your descriptive commit message"
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**
   - Target `develop` for development changes
   - Target `main` for production-ready changes
   - Include description of changes
   - Wait for automated checks to pass

### Environment Deployment Flow

```
Feature Branch → develop → Dev Environment
       ↓
   Pull Request → main → Staging Environment
       ↓
   After approval → Production Environment
```

### Local Development

1. **Setup Azure backend storage**
   ```bash
   ./scripts/setup-azure-backend.sh dev "East US 2" <subscription-id>
   ```

2. **Plan changes locally**
   ```bash
   cd environments/dev
   terraform init
   terraform plan
   ```

3. **Apply changes (dev only)**
   ```bash
   terraform apply
   ```

### Security Guidelines

- Never commit sensitive information
- Use Azure Key Vault for secrets
- Follow principle of least privilege
- Enable diagnostic logging in staging/prod
- Review security scan results in PRs

### Code Standards

- Use consistent naming conventions
- Add comments for complex configurations
- Follow Terraform best practices
- Keep modules focused and reusable
- Document any environment-specific changes

### CI/CD Pipeline

The GitHub Actions workflows automatically:
- ✅ Validate Terraform syntax and formatting
- 🔒 Run security scans (Checkov, Trivy)
- 📋 Generate deployment plans
- 🚀 Deploy to appropriate environments based on branch
- 📊 Store plan artifacts for review

### Getting Help

- Check existing issues and discussions
- Review the main README.md
- Consult Azure AI/ML Landing Zone documentation
- Ask questions in pull request comments
