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


# Configuration object
class Config:
    """Application configuration."""
    
    def __init__(self):
        self.environment: Environment = get_environment()
        self.app_name: str = get_app_name()
        self.is_production: bool = self.environment == "production"
        self.is_uat: bool = self.environment == "uat"
        self.is_development: bool = self.environment == "development"
    
    def __repr__(self) -> str:
        return f"Config(environment={self.environment}, app_name={self.app_name})"


# Global configuration instance
config = Config()
