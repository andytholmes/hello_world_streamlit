#!/bin/bash

# Pre-push Checks Script
# Runs all CI checks locally before pushing to GitHub
# This ensures that GitHub Actions will pass
#
# Usage: ./scripts/pre-push-checks.sh

set -u  # Exit on undefined variables, but not on command errors

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Running Pre-Push CI Checks"
echo "=========================================="
echo ""

FAILED=0

# Function to check command result
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1"
        FAILED=1
        return 1
    fi
}

# 1. Check code formatting (matches CI: ruff format --check .)
echo -e "${BLUE}[1/5] Checking code formatting (ruff format --check)...${NC}"
if ruff format --check . 2>&1; then
    check_result "Code formatting check passed"
else
    echo -e "${RED}✗${NC} Code formatting check failed"
    echo "   Fix with: ruff format ."
    FAILED=1
fi

# 2. Run linting (matches CI: ruff check .)
echo ""
echo -e "${BLUE}[2/5] Running linting checks (ruff check)...${NC}"
if ruff check . 2>&1; then
    check_result "Linting checks passed"
else
    echo -e "${RED}✗${NC} Linting checks failed"
    echo "   Fix with: ruff check --fix ."
    FAILED=1
fi

# 3. Run tests (matches CI: pytest with coverage)
echo ""
echo -e "${BLUE}[3/5] Running unit tests (pytest)...${NC}"
if pytest --tb=short -q > /tmp/pytest_output.txt 2>&1; then
    TEST_COUNT=$(grep -E "passed|failed" /tmp/pytest_output.txt | tail -1 || echo "")
    if [ -n "$TEST_COUNT" ]; then
        echo "   $TEST_COUNT"
    fi
    check_result "All tests passed"
    rm -f /tmp/pytest_output.txt
else
    echo -e "${RED}✗${NC} Tests failed"
    cat /tmp/pytest_output.txt
    rm -f /tmp/pytest_output.txt
    echo ""
    echo "   Run: pytest -v"
    FAILED=1
fi

# 4. Check test coverage (informational, matches CI coverage report)
echo ""
echo -e "${BLUE}[4/5] Checking test coverage...${NC}"
COVERAGE_OUTPUT=$(pytest --cov=. --cov-report=term-missing -q 2>&1 || true)
COVERAGE=$(echo "$COVERAGE_OUTPUT" | grep -E "^TOTAL" | awk '{print $NF}' | sed 's/%//' || echo "0")
if [ -n "$COVERAGE" ] && [ "$COVERAGE" != "0" ]; then
    # Simple numeric comparison without bc
    COVERAGE_INT=$(echo "$COVERAGE" | cut -d'.' -f1 2>/dev/null || echo "0")
    if [ -n "$COVERAGE_INT" ] && [ "$COVERAGE_INT" -ge 70 ] 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Test coverage: ${COVERAGE}%"
    else
        echo -e "${YELLOW}⚠${NC} Test coverage: ${COVERAGE}% (target: >= 70%)"
        # Don't fail on coverage, just warn
    fi
else
    echo -e "${YELLOW}⚠${NC} Could not determine test coverage"
fi

# 5. Check for uncommitted changes (informational only)
echo ""
echo -e "${BLUE}[5/5] Checking git status...${NC}"
UNCOMMITTED=$(git status --porcelain | grep -v "^??" || true)
if [ -z "$UNCOMMITTED" ]; then
    check_result "No uncommitted changes"
else
    echo -e "${YELLOW}⚠${NC} Uncommitted changes detected:"
    git status --short | grep -v "^??" || true
    echo -e "${YELLOW}Note:${NC} These changes should be committed before pushing."
    # Don't fail, just warn - user may want to commit these
fi

echo ""
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Ready to push.${NC}"
    echo "=========================================="
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please fix issues before pushing.${NC}"
    echo "=========================================="
    echo ""
    echo "Quick fixes:"
    echo "  Format code:    ruff format ."
    echo "  Fix linting:    ruff check --fix ."
    echo "  Run tests:      pytest -v"
    exit 1
fi
