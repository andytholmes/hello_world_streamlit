# Hello World Streamlit Application

A minimal but production-grade Streamlit application demonstrating modern DevOps practices, automated testing, and Azure deployment.

## Overview

This application serves as a reference implementation showcasing:
- Clean project structure and code organization
- Automated testing with pytest
- Environment-based configuration
- CI/CD pipeline with GitHub Actions
- Azure App Service deployment

## Features

- Simple "Hello World" Streamlit interface
- Environment-based configuration (Development, UAT, Production)
- Comprehensive unit tests
- Automated CI/CD pipeline
- Production-ready deployment setup

## Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- Git

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd hello_world_steamlit
```

### 2. Create Virtual Environment (Recommended)

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install Dependencies

```bash
# Install production dependencies
pip install -r requirements.txt

# Install development dependencies (for testing and linting)
pip install -r requirements-dev.txt
```

### 4. Configure Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env and set your environment variables (optional)
# ENVIRONMENT=development
# APP_NAME=Hello World Streamlit
```

### 5. Run the Application

```bash
streamlit run app.py
```

The application will start and be accessible at `http://localhost:8501`

## Project Structure

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
├── README.md                   # This file
└── docs/                       # Documentation
    ├── ARCHITECTURE.md         # Architecture documentation
    ├── IMPLEMENTATION_PLAN.md  # Implementation plan
    └── requirements.md         # Requirements document
```

## Development

### Running Tests

```bash
# Run all tests
pytest

# Run tests with coverage
pytest --cov=. --cov-report=html
```

### Code Quality

```bash
# Run linting
ruff check .

# Format code
ruff format .
```

### Branching Strategy

This project uses a lightweight GitFlow-style branching strategy:

- `main` - Production-ready code
- `develop` - Integration branch for completed features
- `feature/*` - Short-lived feature branches

### Development Workflow

1. Create a feature branch from `develop`:
   ```bash
   git checkout develop
   git pull
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and test locally:
   ```bash
   # Run pre-push checks (recommended before every push)
   ./scripts/pre-push-checks.sh
   
   # Or run checks individually:
   pytest
   ruff check .
   ruff format --check .
   streamlit run app.py
   ```

3. **Before pushing, always run CI checks locally:**
   ```bash
   # This ensures GitHub Actions will pass
   ./scripts/pre-push-checks.sh
   ```

4. Commit and push:
   ```bash
   git add .
   git commit -m "Your commit message"
   git push origin feature/your-feature-name
   ```

4. Create a Pull Request to `develop`

## Configuration

The application supports environment-based configuration through environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Application environment (`development`, `uat`, `production`) | `development` |
| `APP_NAME` | Application display name | `Hello World Streamlit` |

Configuration is managed in `config.py` and loaded from:
1. Environment variables (highest priority)
2. `.env` file (if present)
3. Default values (lowest priority)

## Testing

The application includes comprehensive unit tests covering:
- Configuration management
- Environment variable handling
- Application imports and initialization

Run tests with:
```bash
pytest
```

## Deployment

### CI/CD Pipeline

The project uses GitHub Actions for automated CI/CD:

- **Continuous Integration**: Runs on every PR and push
  - Linting checks
  - Unit tests
  - Build validation

- **Continuous Deployment**: 
  - Merge to `develop` → Deploys to UAT
  - Merge to `main` → Deploys to Production

### Azure Deployment

The application is deployed to Azure App Service:
- **UAT**: `hello-world-streamlit-uat`
- **Production**: `hello-world-streamlit-prod`

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed deployment architecture.

## Documentation

- [Requirements](docs/requirements.md) - Functional and non-functional requirements
- [Architecture](docs/ARCHITECTURE.md) - Technical architecture and design decisions
- [Implementation Plan](docs/IMPLEMENTATION_PLAN.md) - Detailed implementation phases
- [Azure Setup Guide](docs/AZURE_SETUP.md) - Azure resource and credentials setup
- [Testing Deployment](docs/TESTING_DEPLOYMENT.md) - How to test the deployment pipeline

## Contributing

1. Follow PEP8 code style guidelines
2. Write tests for new features
3. Ensure all tests pass before submitting PR
4. Update documentation as needed

## License

[Add your license here]

## Support

For issues and questions, please open an issue in the repository.
