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


if __name__ == "__main__":
    main()
