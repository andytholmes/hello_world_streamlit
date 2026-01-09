"""
Unit tests for the Hello World Streamlit application.
"""

import sys
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from config import Config, get_app_name, get_environment


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
        assert hasattr(app, "_format_version_footer")
        assert hasattr(app, "_get_environment_message")

    def test_config_available(self):
        """Test that config is available in app module."""
        from app import config

        assert config is not None
        assert hasattr(config, "environment")
        assert hasattr(config, "app_name")

    def test_format_version_footer_with_version_only(self, monkeypatch):
        """Test formatting version footer with version only."""
        from app import _format_version_footer
        from config import Config

        monkeypatch.setenv("VERSION", "1.0.0")
        monkeypatch.delenv("GIT_COMMIT", raising=False)
        test_config = Config()

        result = _format_version_footer(test_config)
        assert result == "**Version:** 1.0.0"

    def test_format_version_footer_with_commit_only(self, monkeypatch):
        """Test formatting version footer with commit only."""
        from app import _format_version_footer
        from config import Config

        monkeypatch.delenv("VERSION", raising=False)
        monkeypatch.setenv("GIT_COMMIT", "abc123def456")
        test_config = Config()

        result = _format_version_footer(test_config)
        assert "**Commit:** abc123" in result

    def test_format_version_footer_with_version_and_commit_url(self, monkeypatch):
        """Test formatting version footer with version and commit URL."""
        from app import _format_version_footer
        from config import Config

        monkeypatch.setenv("VERSION", "1.0.0")
        monkeypatch.setenv("GIT_COMMIT", "abc123def456")
        monkeypatch.setenv("GITHUB_REPO", "https://github.com/user/repo")
        test_config = Config()

        result = _format_version_footer(test_config)
        assert "**Version:** 1.0.0" in result
        assert "**Commit:** [abc123" in result
        assert "](https://github.com/user/repo/commit/abc123def456)" in result

    def test_format_version_footer_with_short_commit(self, monkeypatch):
        """Test formatting version footer with short commit SHA."""
        from app import _format_version_footer
        from config import Config

        monkeypatch.delenv("VERSION", raising=False)
        monkeypatch.setenv("GIT_COMMIT", "abc")
        test_config = Config()

        result = _format_version_footer(test_config)
        assert "**Commit:** abc" in result

    def test_format_version_footer_empty(self, monkeypatch):
        """Test formatting version footer with no version or commit."""
        from app import _format_version_footer

        # Create a mock config with empty version and commit
        class MockConfig:
            version = ""
            git_commit = ""
            commit_url = ""

        mock_config = MockConfig()
        result = _format_version_footer(mock_config)
        assert result == ""

    def test_format_version_footer_with_default_version(self, monkeypatch):
        """Test formatting version footer with default 'dev' version."""
        from app import _format_version_footer
        from config import Config

        # When no version is set, Config returns "dev" as default
        monkeypatch.delenv("VERSION", raising=False)
        monkeypatch.delenv("GIT_COMMIT", raising=False)
        # Mock the VERSION file to not exist
        import os

        original_join = os.path.join

        def mock_join(*args):
            if "VERSION" in args:
                return "/nonexistent/VERSION"
            return original_join(*args)

        monkeypatch.setattr(os.path, "join", mock_join)
        test_config = Config()

        result = _format_version_footer(test_config)
        # Should include the default "dev" version
        assert "**Version:** dev" in result

    def test_get_environment_message_development(self, monkeypatch):
        """Test getting environment message for development."""
        from app import _get_environment_message
        from config import Config

        monkeypatch.setenv("ENVIRONMENT", "development")
        test_config = Config()

        msg_type, msg_text = _get_environment_message(test_config)
        assert msg_type == "info"
        assert "Development" in msg_text

    def test_get_environment_message_uat(self, monkeypatch):
        """Test getting environment message for UAT."""
        from app import _get_environment_message
        from config import Config

        monkeypatch.setenv("ENVIRONMENT", "uat")
        test_config = Config()

        msg_type, msg_text = _get_environment_message(test_config)
        assert msg_type == "warning"
        assert "UAT" in msg_text

    def test_get_environment_message_production(self, monkeypatch):
        """Test getting environment message for production."""
        from app import _get_environment_message
        from config import Config

        monkeypatch.setenv("ENVIRONMENT", "production")
        test_config = Config()

        msg_type, msg_text = _get_environment_message(test_config)
        assert msg_type == "success"
        assert "Production" in msg_text
