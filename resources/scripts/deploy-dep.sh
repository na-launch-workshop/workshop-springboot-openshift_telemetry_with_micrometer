#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}  Deploy Dependencies${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

print_status() {
    local status=$1
    local message=$2

    case $status in
        "OK")
            echo -e "[${GREEN}✓${NC}] ${message}"
            ;;
        "ERROR")
            echo -e "[${RED}✗${NC}] ${message}"
            ERRORS=$((ERRORS + 1))
            ;;
        "WARNING")
            echo -e "[${YELLOW}⚠${NC}] ${message}"
            WARNINGS=$((WARNINGS + 1))
            ;;
        "INFO")
            echo -e "[${BLUE}ℹ${NC}] ${message}"
            ;;
    esac
}


# Check requirements

# 1. Check environment variables

if [[ -n "${WS_USERID:-}" ]]; then
    OC_USER="${WS_USERID}"

    print_status "INFO" "Use WS_USERID at your own risk"
    print_status "OK" "Using provided WS_USERID: ${OC_USER}"

else
    OC_USER=$(oc whoami 2>/dev/null || echo "")
    
    if [[ -n "$OC_USER" ]]; then
        print_status "OK" "Using OpenShift user: ${OC_USER}"
    
        if [[ "$OC_USER" == "kube:admin" ]]; then
            print_status "WARNING" "You are logged in as 'kubeadmin', which is not recommended for workshop use."
            print_status "INFO" "Please login with your assigned user: oc login <cluster-url> --token=<your-token>"

            OC_USER="kubeadmin"
        fi

    else
        print_status "ERROR" "oc login is not set"
        print_status "INFO" "Please login into OpenShift first: oc login <cluster-url> --token=<your-token>"
        
        exit 1
    fi
fi

print_status "INFO" "User set to: ${OC_USER}" 

CURRENT_PROJECT=$(oc project -q 2>/dev/null || echo "")
EXPECTED_PROJECT="${OC_USER}-devspaces"

if [[ -n "$CURRENT_PROJECT" ]]; then
    if [[ "$CURRENT_PROJECT" == "$EXPECTED_PROJECT" ]]; then
        print_status "OK" "Current project follows convention: ${CURRENT_PROJECT}"
    
    else
        print_status "WARNING" "Current project does not follow convention"
        print_status "INFO" "Current: ${CURRENT_PROJECT}, Expected: ${EXPECTED_PROJECT}"
        print_status "INFO" "You can switch with: oc project ${EXPECTED_PROJECT}"
    
    fi
else
    print_status "ERROR" "Cannot determine current OpenShift project"
    print_status "INFO" "Please ensure you are logged into OpenShift and have a valid project"

    exit 1
fi

print_status "INFO" "Current project: ${CURRENT_PROJECT}"

echo ""

#  Get script directory and find peer k8s directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
print_status "INFO" "Script directory: ${SCRIPT_DIR}"

# Go up to parent directory, then down to k8s (peer folder)
RESOURCES_DIR="$(dirname "${SCRIPT_DIR}")/k8s"
print_status "INFO" "Looking for resources in: ${RESOURCES_DIR}"

if [[ -d "$RESOURCES_DIR" ]]; then
    print_status "INFO" "Applying resources from: ${RESOURCES_DIR}"
    
    if oc apply -f "$RESOURCES_DIR" &>/dev/null; then
        print_status "OK" "Resources applied successfully"
    else
        print_status "ERROR" "Failed to apply resources"
        print_status "INFO" "Try running manually: oc apply -f ${RESOURCES_DIR}"
    fi
else
    print_status "WARNING" "Resources directory not found: ${RESOURCES_DIR}"
    print_status "INFO" "Expected structure: resources/k8s/ and resources/scripts/ as peers"
fi

echo ""
