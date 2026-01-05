# Hello World Streamlit Application – Architecture Document

## 1. Document Information

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2024 |
| **Status** | Draft |
| **Author** | Development Team |

---

## 2. Executive Summary

This document describes the technical architecture for a Hello World Streamlit application deployed to Microsoft Azure. The architecture follows modern cloud-native principles, emphasizing automation, security, and maintainability through CI/CD pipelines, environment-based configuration, and comprehensive testing.

---

## 3. System Overview

### 3.1 Purpose
The application serves as a minimal but production-grade reference implementation demonstrating:
- Clean project structure and code organization
- Automated testing and quality assurance
- Safe deployment practices with environment separation
- Modern DevOps workflows

### 3.2 Key Characteristics
- **Technology Stack**: Python 3.x, Streamlit
- **Hosting**: Azure App Service (Linux)
- **CI/CD**: GitHub Actions
- **Testing**: pytest
- **Code Quality**: PEP8, ruff/flake8

---

## 4. System Architecture

### 4.1 High-Level Architecture

```
┌────────────────────────────────────────────────────────────┐
│                        GitHub Repository                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   main       │  │   develop    │  │  feature/*   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────────────────────────────────────────┘
                            │
                            │ Push/PR Events
                            ▼
┌────────────────────────────────────────────────────────────┐
│                    GitHub Actions CI/CD                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1. Install Dependencies                             │  │
│  │  2. Run Linting (ruff/flake8)                        │  │
│  │  3. Run Unit Tests (pytest)                          │  │
│  │  4. Build Application                                │  │
│  │  5. Deploy to Azure App Service                      │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
                            │
                            │ Deployment
                            ▼
┌────────────────────────────────────────────────────────────┐
│                      Azure Cloud                           │
│  ┌──────────────────────┐      ┌──────────────────────┐    │
│  │  App Service (UAT)   │      │ App Service (Prod)   │    │
│  │  - Linux Runtime     │      │  - Linux Runtime     │    │
│  │  - Python 3.x        │      │  - Python 3.x        │    │
│  │  - Streamlit App     │      │  - Streamlit App     │    │
│  └──────────────────────┘      └──────────────────────┘    │
│           │                              │                 │
│           └──────────────┬───────────────┘                 │
│                          │                                 │
│                          ▼                                 │
│              ┌──────────────────────┐                      │
│              │  Azure Key Vault     │                      │
│              │  (Secrets Management)│                      │
│              └──────────────────────┘                      │
└────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS
                            ▼
                    ┌───────────────┐
                    │   End Users   │
                    └───────────────┘
```

### 4.2 Component Architecture

#### 4.2.1 Application Layer
- **Component**: `app.py`
- **Responsibility**: Main Streamlit application entry point
- **Dependencies**: streamlit, python-dotenv (for environment variables)
- **Configuration**: Environment variables for environment-specific settings

#### 4.2.2 Testing Layer
- **Component**: `tests/test_app.py`
- **Framework**: pytest
- **Coverage**: Unit tests for application logic and startup validation
- **Mocking**: Streamlit components where necessary

#### 4.2.3 CI/CD Layer
- **Component**: `.github/workflows/ci-cd.yml`
- **Triggers**: Pull requests, pushes to `develop` and `main`
- **Stages**:
  1. Lint and format check
  2. Unit test execution
  3. Build validation
  4. Deployment (conditional on branch)

---

## 5. Deployment Architecture

### 5.1 Environment Strategy

| Environment | Branch | Azure App Service | Purpose |
|------------|--------|-------------------|---------|
| **Development** | Local | N/A | Local development and testing |
| **UAT** | `develop` | `hello-world-streamlit-uat` | Integration testing and validation |
| **Production** | `main` | `hello-world-streamlit-prod` | Live production environment |

### 5.2 Azure App Service Configuration

#### 5.2.1 Runtime Configuration
- **OS**: Linux
- **Runtime Stack**: Python 3.x (latest stable)
- **Startup Command**: `streamlit run app.py --server.port=8000 --server.address=0.0.0.0`
- **Port**: 8000 (internal), exposed via Azure App Service HTTP/HTTPS

#### 5.2.2 Application Settings
Environment variables configured per environment:
- `ENVIRONMENT`: `development`, `uat`, or `production`
- `APP_NAME`: Application display name
- Additional environment-specific settings as needed

#### 5.2.3 Scaling Configuration
- **Initial**: Basic tier (B1) for cost optimization
- **Scaling**: Manual scaling available, can be upgraded to Standard tier if needed
- **Instances**: 1 instance per environment (can scale horizontally if required)

### 5.3 Deployment Flow

```
Developer Push/PR
       │
       ▼
GitHub Actions Triggered
       │
       ├──► Lint Check ──┐
       │                  │
       ├──► Unit Tests ──┤──► All Pass? ──► Continue
       │                  │
       └──► Build ────────┘
                            │
                            ▼
                    Branch Check
                            │
                ┌───────────┴───────────┐
                │                       │
         develop branch          main branch
                │                       │
                ▼                       ▼
        Deploy to UAT          Deploy to Production
                │                       │
                └───────────┬───────────┘
                            │
                            ▼
                    Azure App Service
                    (Environment-specific)
```

---

## 6. Data Flow

### 6.1 Request Flow

```
User Browser
    │
    │ HTTPS Request
    ▼
Azure App Service (Load Balancer)
    │
    │ Route to Python Runtime
    ▼
Streamlit Application (app.py)
    │
    │ Process Request
    ▼
Render "Hello World" UI
    │
    │ HTTP Response
    ▼
User Browser
```

### 6.2 Configuration Flow

```
GitHub Secrets / Azure Key Vault
    │
    │ Environment Variables
    ▼
GitHub Actions Workflow
    │
    │ Inject during deployment
    ▼
Azure App Service Configuration
    │
    │ Runtime Environment
    ▼
Streamlit Application
```

---

## 7. Security Architecture

### 7.1 Secrets Management

#### 7.1.1 GitHub Secrets
- **Purpose**: Store Azure Service Principal credentials
- **Secrets Required**:
  - `AZURE_CLIENT_ID`: Service Principal Client ID
  - `AZURE_CLIENT_SECRET`: Service Principal Client Secret
  - `AZURE_TENANT_ID`: Azure Tenant ID
  - `AZURE_SUBSCRIPTION_ID`: Azure Subscription ID

#### 7.1.2 Azure Key Vault (Future Enhancement)
- Centralized secrets management
- Integration with App Service managed identity
- Rotation policies

### 7.2 Authentication & Authorization

#### 7.2.1 Azure Service Principal
- **Purpose**: GitHub Actions authentication to Azure
- **Permissions**: 
  - Contributor role on Resource Group
  - App Service deployment permissions
- **Scope**: Limited to specific resource groups

#### 7.2.2 Application Security
- **HTTPS**: Enforced via Azure App Service (TLS 1.2+)
- **No Authentication**: As per requirements, no user authentication implemented
- **Network Security**: Azure App Service network isolation (if configured)

### 7.3 Code Security

- **Static Analysis**: Linting tools (ruff/flake8) check for security issues
- **Dependency Scanning**: `requirements.txt` dependencies should be regularly audited
- **No Hardcoded Secrets**: All secrets via environment variables or Azure configuration

---

## 8. Technology Stack

### 8.1 Application Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Language** | Python | 3.x (latest stable) | Application runtime |
| **Web Framework** | Streamlit | Latest | Web UI framework |
| **Environment Config** | python-dotenv | Latest | Environment variable management |

### 8.2 Development Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Testing** | pytest | Latest | Unit testing framework |
| **Linting** | ruff | Latest | Fast Python linter and formatter |
| **Code Quality** | PEP8 | Standard | Code style guidelines |

### 8.3 Infrastructure Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Source Control** | GitHub | Version control and collaboration |
| **CI/CD** | GitHub Actions | Automated testing and deployment |
| **Hosting** | Azure App Service | Application hosting |
| **Runtime** | Linux (Python) | Application runtime environment |

---

## 9. Project Structure

```
hello-world-streamlit/
├── app.py                      # Main Streamlit application
├── config.py                   # Configuration management
├── requirements.txt            # Production dependencies
├── requirements-dev.txt        # Development dependencies
├── .env.example                # Example environment variables
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # GitHub Actions CI/CD pipeline
├── tests/
│   ├── __init__.py
│   └── test_app.py            # Unit tests
├── .gitignore                  # Git ignore rules
├── .ruff.toml                  # Ruff configuration (optional)
├── README.md                   # Project documentation
├── ARCHITECTURE.md             # This document
└── requirements.md             # Requirements document
```

---

## 10. Design Decisions

### 10.1 Why Streamlit?
- **Rapid Development**: Minimal code required for web UI
- **Python Native**: Aligns with team's Python expertise
- **Simple Deployment**: Works well with Azure App Service

### 10.2 Why Azure App Service?
- **Managed Service**: Minimal infrastructure management
- **Python Support**: Native Python runtime support
- **CI/CD Integration**: Easy integration with GitHub Actions
- **Cost Effective**: Pay-as-you-go pricing suitable for small applications

### 10.3 Why GitHub Actions?
- **Native Integration**: Built into GitHub repository
- **No Additional Costs**: Free for public repositories
- **Flexibility**: YAML-based configuration, extensive marketplace

### 10.4 Why pytest?
- **Industry Standard**: Widely adopted Python testing framework
- **Extensibility**: Rich plugin ecosystem
- **Simplicity**: Easy to write and maintain tests

### 10.5 Why Environment-Based Configuration?
- **Security**: Secrets not in code
- **Flexibility**: Different settings per environment
- **Best Practice**: Aligns with 12-factor app principles

---

## 11. Scalability Considerations

### 11.1 Current Design
- Single instance per environment
- Stateless application (no session storage)
- Suitable for low to moderate traffic

### 11.2 Future Scalability Options
- **Horizontal Scaling**: Add multiple App Service instances
- **Auto-scaling**: Configure based on CPU/memory metrics
- **Containerization**: Migrate to Azure Container Apps for better scaling
- **CDN**: Add Azure CDN for static content (if applicable)

---

## 12. Monitoring & Observability

### 12.1 Current Implementation
- **Azure App Service Logs**: Built-in application logs
- **GitHub Actions Logs**: CI/CD execution logs

### 12.2 Future Enhancements (Optional)
- **Azure Application Insights**: Application performance monitoring
- **Custom Metrics**: Track application-specific metrics
- **Alerting**: Configure alerts for errors and performance issues

---

## 13. Disaster Recovery & Backup

### 13.1 Code Backup
- **GitHub**: Primary code repository with full history
- **Branch Protection**: `main` branch protected

### 13.2 Application Recovery
- **Azure App Service**: Built-in redundancy and availability
- **Deployment Slots**: Can use deployment slots for zero-downtime deployments (future)

---

## 14. Compliance & Standards

### 14.1 Code Standards
- **PEP8**: Python code style guidelines
- **Type Hints**: Consider adding type hints for better code quality
- **Documentation**: Inline comments and docstrings

### 14.2 Security Standards
- **No Secrets in Code**: All secrets via environment variables
- **HTTPS Only**: Enforced TLS encryption
- **Dependency Management**: Regular updates and security audits

---

## 15. Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Azure Service Principal Compromise** | High | Rotate credentials regularly, use least privilege |
| **Dependency Vulnerabilities** | Medium | Regular dependency updates, security scanning |
| **Deployment Failures** | Medium | Automated rollback, deployment slots (future) |
| **Cost Overruns** | Low | Monitor Azure costs, use appropriate service tiers |

---

## 16. Future Enhancements

As outlined in requirements, potential future enhancements include:
1. **Infrastructure as Code**: Bicep or Terraform for Azure resources
2. **Containerization**: Docker-based deployment
3. **End-to-End Testing**: Automated browser testing
4. **Application Insights**: Comprehensive monitoring and logging
5. **Deployment Slots**: Blue-green deployments for zero downtime

---

## 17. References

- [Streamlit Documentation](https://docs.streamlit.io/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [pytest Documentation](https://docs.pytest.org/)
- [PEP 8 Style Guide](https://pep8.org/)

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024 | Development Team | Initial architecture document |
