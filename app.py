"""
Hello World Streamlit Application

A minimal Streamlit application that displays a "Hello World" message
with environment-based configuration support.
"""

import streamlit as st

from config import config

# Configure page
st.set_page_config(
    page_title=config.app_name,
    page_icon="👋",
    layout="centered",
)


def _format_version_footer(config_obj):
    """
    Format version and commit information for display.

    Args:
        config_obj: Configuration object with version and commit info

    Returns:
        str: Formatted footer text, or empty string if no version/commit info
    """
    if not (config_obj.version or config_obj.git_commit):
        return ""

    version_parts = []
    if config_obj.version:
        version_parts.append(f"**Version:** {config_obj.version}")

    if config_obj.commit_url and config_obj.git_commit:
        commit_short = (
            config_obj.git_commit[:7]
            if len(config_obj.git_commit) >= 7
            else config_obj.git_commit
        )
        version_parts.append(f"**Commit:** [{commit_short}]({config_obj.commit_url})")
    elif config_obj.git_commit:
        commit_short = (
            config_obj.git_commit[:7]
            if len(config_obj.git_commit) >= 7
            else config_obj.git_commit
        )
        version_parts.append(f"**Commit:** {commit_short}")

    return " | ".join(version_parts) if version_parts else ""


def _display_version_footer():
    """Display version and commit information unobtrusively at the bottom."""
    footer_text = _format_version_footer(config)
    if footer_text:
        # Add spacing and small text at the bottom
        st.markdown("<br>", unsafe_allow_html=True)
        st.markdown("---")
        st.caption(footer_text)


def _get_environment_message(config_obj):
    """
    Get the environment-specific message.

    Args:
        config_obj: Configuration object

    Returns:
        tuple: (message_type, message_text) where message_type is one of:
               'info', 'warning', 'success', or None
    """
    if config_obj.is_development:
        return ("info", "🔧 Running in Development mode")
    elif config_obj.is_uat:
        return ("warning", "🧪 Running in UAT mode")
    elif config_obj.is_production:
        return ("success", "🚀 Running in Production mode")
    return (None, "")


def _render_main_content(config_obj):
    """
    Render the main application content.
    This function contains the UI logic separated for testability.

    Args:
        config_obj: Configuration object
    """
    # Display header
    st.title("👋 Hello World!")

    # Display application name from configuration
    st.subheader(config_obj.app_name)

    # Display environment information
    st.write(f"**Environment:** {config_obj.environment.upper()}")

    # Display a welcome message
    st.write("Welcome to the Hello World Streamlit application!")

    # Environment-specific message
    msg_type, msg_text = _get_environment_message(config_obj)
    if msg_type == "info":
        st.info(msg_text)
    elif msg_type == "warning":
        st.warning(msg_text)
    elif msg_type == "success":
        st.success(msg_text)

    # Display version and commit info unobtrusively at the bottom
    _display_version_footer()


# Main application
def main():
    """Main application function."""
    _render_main_content(config)


if __name__ == "__main__":
    main()
