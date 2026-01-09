"""
Configuration management for the Hello World Streamlit application.
Supports environment-based configuration using environment variables.
"""

import os
from typing import Literal

from dotenv import load_dotenv

# Load environment variables from .env file if it exists
load_dotenv()

# Environment type
Environment = Literal["development", "uat", "production"]


def get_environment() -> Environment:
    """
    Get the current environment from environment variable.
    Defaults to 'development' if not set.

    Returns:
        Environment: The current environment ('development', 'uat', or 'production')
    """
    env = os.getenv("ENVIRONMENT", "development").lower()
    valid_envs = ["development", "uat", "production"]

    if env not in valid_envs:
        env = "development"

    return env  # type: ignore


def get_app_name() -> str:
    """
    Get the application name from environment variable.
    Defaults to 'Hello World Streamlit' if not set.

    Returns:
        str: The application name
    """
    return os.getenv("APP_NAME", "Hello World Streamlit")


def get_version() -> str:
    """
    Get the application version from environment variable or VERSION file.
    Defaults to 'dev' if not set.

    Returns:
        str: The application version
    """
    # Try environment variable first (set during deployment)
    version = os.getenv("VERSION")
    if version:
        return version

    # Try reading from VERSION file
    try:
        version_file = os.path.join(os.path.dirname(__file__), "VERSION")
        with open(version_file, encoding="utf-8") as f:
            version = f.read().strip()
        if version:
            return version
    except (OSError, FileNotFoundError):
        # If the VERSION file is missing or unreadable, fall back to the default
        # "dev" version returned below.
        pass

    return "dev"


def get_git_commit() -> str:
    """
    Get the git commit SHA from environment variable.
    Defaults to empty string if not set.

    Returns:
        str: The git commit SHA
    """
    return os.getenv("GIT_COMMIT", "")


def get_github_repo() -> str:
    """
    Get the GitHub repository URL from environment variable.
    Defaults to empty string if not set.

    Returns:
        str: The GitHub repository URL
    """
    return os.getenv("GITHUB_REPO", "")


# Configuration object
class Config:
    """Application configuration."""

    def __init__(self):
        self.environment: Environment = get_environment()
        self.app_name: str = get_app_name()
        self.version: str = get_version()
        self.git_commit: str = get_git_commit()
        self.github_repo: str = get_github_repo()
        self.is_production: bool = self.environment == "production"
        self.is_uat: bool = self.environment == "uat"
        self.is_development: bool = self.environment == "development"

    @property
    def commit_url(self) -> str:
        """Get the GitHub commit URL."""
        if self.github_repo and self.git_commit:
            # Remove .git suffix if present (use endswith check, not rstrip)
            repo_url = (
                self.github_repo[:-4]
                if self.github_repo.endswith(".git")
                else self.github_repo
            )
            return f"{repo_url}/commit/{self.git_commit}"
        return ""

    def __repr__(self) -> str:
        return f"Config(environment={self.environment}, app_name={self.app_name}, version={self.version})"


# Global configuration instance
config = Config()
