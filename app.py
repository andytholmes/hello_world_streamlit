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


def _display_version_footer():
    """
    Display version and commit information unobtrusively at the bottom.
    """
    if config.version or config.git_commit:
        # Add spacing and small text at the bottom
        st.markdown("<br>", unsafe_allow_html=True)
        st.markdown("---")

        version_parts = []
        if config.version:
            version_parts.append(f"**Version:** {config.version}")

        if config.commit_url and config.git_commit:
            commit_short = (
                config.git_commit[:7]
                if len(config.git_commit) >= 7
                else config.git_commit
            )
            version_parts.append(f"**Commit:** [{commit_short}]({config.commit_url})")
        elif config.git_commit:
            commit_short = (
                config.git_commit[:7]
                if len(config.git_commit) >= 7
                else config.git_commit
            )
            version_parts.append(f"**Commit:** {commit_short}")

        if version_parts:
            # Use caption for small, unobtrusive text
            footer_text = " | ".join(version_parts)
            st.caption(footer_text)


# Main application
def main():
    """Main application function."""
    # Display header
    st.title("👋 Hello World!")

    # Display application name from configuration
    st.subheader(config.app_name)

    # Display environment information
    st.write(f"**Environment:** {config.environment.upper()}")

    # Display a welcome message
    st.write("Welcome to the Hello World Streamlit application!")

    # Environment-specific message
    if config.is_development:
        st.info("🔧 Running in Development mode")
    elif config.is_uat:
        st.warning("🧪 Running in UAT mode")
    elif config.is_production:
        st.success("🚀 Running in Production mode")

    # Display version and commit info unobtrusively at the bottom
    _display_version_footer()


if __name__ == "__main__":
    main()
