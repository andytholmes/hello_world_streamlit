# Hello World Streamlit Application – Requirements

## 1. Overview
This document defines the functional and non-functional requirements for a **Hello World Streamlit Python application**, developed using **standard SDLC practices** and deployed to **Microsoft Azure**. The application will follow modern DevOps principles, including automated CI/CD via **GitHub Actions**, environment-based deployments, and test-driven development.

The primary goal is to provide a minimal but production-grade reference implementation that demonstrates:
- Clean project structure
- Automated testing
- Safe deployment practices
- Clear separation of environments (Dev, UAT, Production)

---

## 2. Scope

### In Scope
- A Streamlit web application displaying a basic "Hello World" interface
- Source control using GitHub
- CI/CD pipeline using GitHub Actions
- Azure-based hosting and deployment
- Unit testing executed locally and in CI
- Branching and pull request strategy
- Automated deployments to UAT and Production

### Out of Scope
- Authentication or authorization
- Persistent storage or databases
- Advanced UI/UX
- Performance or load testing

---

## 3. Functional Requirements

### FR-1: Application Behaviour
- The application SHALL be built using **Python** and **Streamlit**.
- The application SHALL display a "Hello World" message in the browser.
- The application SHALL start using the command:
  ```bash
  streamlit run app.py
  ```

### FR-2: Environment Configuration
- The application SHALL support environment-based configuration using environment variables.
- At minimum, the following environments SHALL exist:
  - Development (local)
  - UAT
  - Production

---

## 4. Non-Functional Requirements

### NFR-1: Code Quality
- Code SHALL follow PEP8 standards.
- Static analysis and linting SHOULD be supported (e.g. `ruff` or `flake8`).

### NFR-2: Testability
- Unit tests SHALL be written using `pytest`.
- Tests SHALL be executable locally via:
  ```bash
  pytest
  ```
- CI pipelines SHALL fail if tests do not pass.

### NFR-3: Security
- Secrets (e.g. Azure credentials) SHALL NOT be committed to source control.
- Secrets SHALL be managed via GitHub Secrets and Azure configuration.

---

## 5. Project Structure

```
hello-world-streamlit/
├── app.py
├── requirements.txt
├── requirements-dev.txt
├── tests/
│   └── test_app.py
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── README.md
└── requirements.md
```

---

## 6. SDLC & Branching Strategy

### 6.1 Branching Model
A **lightweight GitFlow-style** strategy SHALL be used:

- `main` – Production-ready code
- `develop` – Integration branch for completed features
- `feature/*` – Short-lived feature branches

### 6.2 Development Workflow
1. Developer creates a `feature/*` branch from `develop`
2. Unit tests are run locally
3. Pull Request (PR) opened into `develop`
4. CI pipeline runs tests and validation
5. On PR merge, deployment to **UAT** is triggered
6. PR from `develop` → `main` triggers **Production deployment**

---

## 7. CI/CD Pipeline (GitHub Actions)

### 7.1 Continuous Integration
The CI pipeline SHALL:
- Trigger on pull requests and pushes
- Install dependencies
- Run unit tests
- Fail fast on errors

### 7.2 Continuous Deployment

| Event | Target Environment |
|-----|-------------------|
| PR merged to `develop` | UAT |
| PR merged to `main` | Production |

The pipeline SHALL:
- Build the application
- Deploy to Azure
- Use environment-specific configuration

---

## 8. Azure Deployment

### 8.1 Hosting
- The application SHALL be hosted on **Azure App Service** (Linux, Python runtime).
- Streamlit SHALL be exposed via HTTP/HTTPS.

### 8.2 Environments
- Separate Azure App Services SHALL exist for:
  - UAT
  - Production

### 8.3 Deployment Method
- Deployments SHALL be executed using GitHub Actions.
- Azure authentication SHALL use a Service Principal.

---

## 9. Testing Strategy

### Unit Tests
- Focus on validating application startup and basic logic
- Mock Streamlit components where necessary

### Test Execution
- Developers run tests locally before pushing
- CI runs all tests automatically on PRs and merges

---

## 10. Acceptance Criteria

- Application displays "Hello World" successfully
- All unit tests pass locally and in CI
- PRs trigger automated validation
- Merges to `develop` deploy to UAT
- Merges to `main` deploy to Production
- No secrets stored in source control

---

## 11. Future Enhancements (Optional)
- Infrastructure as Code using Bicep or Terraform
- Containerised deployment using Docker
- End-to-end tests
- Monitoring and logging via Azure Application Insights

