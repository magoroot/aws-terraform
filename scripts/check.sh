#!/usr/bin/env bash

# Quality checks script for Terraform
# Runs formatting, validation, and linting

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

echo "🔍 Running Terraform quality checks..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter
CHECKS_PASSED=0
CHECKS_FAILED=0

# 1. Format Check
echo -e "\n${YELLOW}1. Checking formatting...${NC}"
if command -v terraform &> /dev/null; then
    cd "${PROJECT_ROOT}"
    if terraform fmt -recursive -check > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Format check passed${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Format check failed${NC}"
        echo "  Run: terraform fmt -recursive to fix"
        ((CHECKS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠ Terraform not installed, skipping format check${NC}"
fi

# 2. Validation
echo -e "\n${YELLOW}2. Running terraform validate...${NC}"
if command -v terraform &> /dev/null; then
    VALIDATION_ERRORS=0
    
    for stack in bootstrap network; do
        cd "${PROJECT_ROOT}/stacks/${stack}"
        if terraform validate > /dev/null 2>&1; then
            echo -e "${GREEN}✓ stacks/${stack} validated${NC}"
            ((CHECKS_PASSED++))
        else
            echo -e "${RED}✗ stacks/${stack} validation failed${NC}"
            terraform validate
            ((CHECKS_FAILED++))
        fi
    done
else
    echo -e "${YELLOW}⚠ Terraform not installed, skipping validation${NC}"
fi

# 3. TFLint
echo -e "\n${YELLOW}3. Running tflint...${NC}"
if command -v tflint &> /dev/null; then
    cd "${PROJECT_ROOT}"
    if tflint --init > /dev/null 2>&1; then
        for stack in bootstrap network; do
            if tflint "stacks/${stack}" 2>&1 | grep -qi "error"; then
                echo -e "${RED}✗ stacks/${stack} linting issues found${NC}"
                ((CHECKS_FAILED++))
            else
                echo -e "${GREEN}✓ stacks/${stack} lint check passed${NC}"
                ((CHECKS_PASSED++))
            fi
        done
    fi
else
    echo -e "${YELLOW}⚠ tflint not installed${NC}"
    echo "  Install: brew install tflint"
fi

# 4. tfsec (Security)
echo -e "\n${YELLOW}4. Running tfsec...${NC}"
if command -v tfsec &> /dev/null; then
    cd "${PROJECT_ROOT}"
    if tfsec . -f json > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Security scan passed${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗ Security issues found${NC}"
        tfsec .
        ((CHECKS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠ tfsec not installed${NC}"
    echo "  Install: brew install tfsec"
fi

# Summary
echo -e "\n${YELLOW}═══════════════════════════════════════${NC}"
echo -e "Checks passed: ${GREEN}${CHECKS_PASSED}${NC}"
echo -e "Checks failed: ${RED}${CHECKS_FAILED}${NC}"
echo -e "${YELLOW}═══════════════════════════════════════${NC}"

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ All checks passed!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some checks failed${NC}"
    exit 1
fi
