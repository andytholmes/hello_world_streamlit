#!/bin/bash

# Script to create a Pull Request from develop to main
# Usage: ./scripts/create-pr.sh [GITHUB_TOKEN]
# Or create manually using the instructions below

set -e

REPO="andytholmes/hello_world_streamlit"
BASE="main"
HEAD="develop"
TITLE="Release v1.0.0 - Production Ready Implementation"
PR_DESCRIPTION_FILE="PR_DESCRIPTION.md"
COMPARE_URL="https://github.com/${REPO}/compare/${BASE}...${HEAD}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Create Pull Request: develop → main"
echo "=========================================="
echo ""

# Check if GitHub token is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}GitHub token not provided. Creating PR manually...${NC}"
    echo ""
    echo -e "${BLUE}Instructions:${NC}"
    echo "1. Open this URL in your browser:"
    echo "   ${COMPARE_URL}"
    echo ""
    echo "2. Click 'Create pull request' button"
    echo ""
    echo "3. Use this title:"
    echo "   ${TITLE}"
    echo ""
    echo "4. Copy the description from this file:"
    echo "   ${PR_DESCRIPTION_FILE}"
    echo ""
    echo -e "${GREEN}Alternative: Provide a GitHub token to create PR automatically:${NC}"
    echo "  ./scripts/create-pr.sh YOUR_GITHUB_TOKEN"
    echo ""
    echo "To get a token: https://github.com/settings/tokens"
    echo "  (Requires 'repo' scope)"
    echo ""
    
    # Try to open browser
    if command -v open &> /dev/null; then
        echo "Opening GitHub compare page in browser..."
        open "${COMPARE_URL}" 2>/dev/null || true
    elif command -v xdg-open &> /dev/null; then
        echo "Opening GitHub compare page in browser..."
        xdg-open "${COMPARE_URL}" 2>/dev/null || true
    fi
    
    exit 0
fi

GITHUB_TOKEN="$1"

# Check if Python is available for JSON handling
if command -v python3 &> /dev/null; then
    # Read PR description and escape for JSON using Python
    PR_BODY=$(python3 -c "
import json
import sys
with open('${PR_DESCRIPTION_FILE}', 'r') as f:
    content = f.read()
print(json.dumps(content))
")
else
    echo "Error: Python 3 required for automatic PR creation"
    echo "Please create the PR manually using the instructions above"
    exit 1
fi

# Create PR using GitHub API
echo "Creating Pull Request..."
echo "  Title: ${TITLE}"
echo "  Base: ${BASE}"
echo "  Head: ${HEAD}"
echo ""

# Create JSON payload
JSON_PAYLOAD=$(python3 -c "
import json
import sys
with open('${PR_DESCRIPTION_FILE}', 'r') as f:
    body = f.read()
payload = {
    'title': '${TITLE}',
    'body': body,
    'base': '${BASE}',
    'head': '${HEAD}'
}
print(json.dumps(payload))
")

RESPONSE=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/${REPO}/pulls" \
  -d "${JSON_PAYLOAD}")

# Check if PR was created successfully using Python
PR_URL=$(echo "$RESPONSE" | python3 -c "
import json
import sys
try:
    data = json.load(sys.stdin)
    if 'html_url' in data:
        print(data['html_url'])
    elif 'message' in data:
        print('ERROR: ' + data['message'])
        sys.exit(1)
    else:
        print('ERROR: Unexpected response')
        sys.exit(1)
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
" 2>&1)

if [[ "$PR_URL" == ERROR:* ]]; then
    echo -e "${YELLOW}Error creating Pull Request:${NC}"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    exit 1
elif [ -n "$PR_URL" ] && [ "$PR_URL" != "null" ]; then
    echo -e "${GREEN}✓ Pull Request created successfully!${NC}"
    echo ""
    echo "PR URL: ${PR_URL}"
    echo ""
    echo "You can view it in your browser:"
    echo "  ${PR_URL}"
    
    # Try to open in browser
    if command -v open &> /dev/null; then
        open "${PR_URL}" 2>/dev/null || true
    elif command -v xdg-open &> /dev/null; then
        xdg-open "${PR_URL}" 2>/dev/null || true
    fi
else
    echo "Error: Unexpected response"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    exit 1
fi
