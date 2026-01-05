"""
Unit tests for the Hello World Streamlit application.
"""
import pytest
import sys
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from config import Config, get_environment, get_app_name


class TestConfig:
    """Test configuration management."""
    
    def test_get_environment_default(self, monkeypatch):
        """Test that get_environment returns 'development' by default."""
        monkeypatch.delenv("ENVIRONMENT", raising=False)
        assert get_environment() == "development"
    
    def test_get_environment_from_env(self, monkeypatch):
        """Test that get_environment reads from environment variable."""
        monkeypatch.setenv("ENVIRONMENT", "production")
        assert get_environment() == "production"
    
    def test_get_app_name_default(self, monkeypatch):
        """Test that get_app_name returns default value."""
        monkeypatch.delenv("APP_NAME", raising=False)
        assert get_app_name() == "Hello World Streamlit"
    
    def test_get_app_name_from_env(self, monkeypatch):
        """Test that get_app_name reads from environment variable."""
        monkeypatch.setenv("APP_NAME", "Test App")
        assert get_app_name() == "Test App"
    
    def test_config_initialization(self, monkeypatch):
        """Test Config class initialization."""
        monkeypatch.setenv("ENVIRONMENT", "uat")
        monkeypatch.setenv("APP_NAME", "Test App")
        
        test_config = Config()
        assert test_config.environment == "uat"
        assert test_config.app_name == "Test App"
        assert test_config.is_uat is True
        assert test_config.is_production is False
        assert test_config.is_development is False
    
    def test_config_production_flags(self, monkeypatch):
        """Test production environment flags."""
        monkeypatch.setenv("ENVIRONMENT", "production")
        test_config = Config()
        assert test_config.is_production is True
        assert test_config.is_uat is False
        assert test_config.is_development is False
    
    def test_config_development_flags(self, monkeypatch):
        """Test development environment flags."""
        monkeypatch.setenv("ENVIRONMENT", "development")
        test_config = Config()
        assert test_config.is_development is True
        assert test_config.is_uat is False
        assert test_config.is_production is False


class TestApplication:
    """Test application functionality."""
    
    def test_app_imports(self):
        """Test that the application can be imported without errors."""
        import app
        assert app is not None
        assert hasattr(app, "main")
    
    def test_config_available(self):
        """Test that config is available in app module."""
        from app import config
        assert config is not None
        assert hasattr(config, "environment")
        assert hasattr(config, "app_name")
