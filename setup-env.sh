#!/bin/bash

# NOTE:  This should not be a needed script.  Ideally devspaces or host container environment will
#        be setup with the +x permissions.  This is just a convenience script to help
#        ensure the needed scripts are executable.  But also since init-shell needs to be sourced this doesn't get pulled in.


set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}  Setup Environment And Validate${NC}"
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

# 1. Check environment variables
echo -e "${YELLOW}1. Checking Environment Variables...${NC}"

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

            OC_USER="user100"
        fi

    else
        print_status "ERROR" "oc login is not set"
        print_status "INFO" "Please login into OpenShift first: oc login <cluster-url> --token=<your-token>"
        
        exit 1
    fi
fi

print_status "INFO" "User set to: ${OC_USER}" 

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# setup validate-workshop.sh
# Path to script
SCRIPT_NAME="validate-workshop.sh"
VALIDATION_SCRIPT="${SCRIPT_DIR}/resources/scripts/${SCRIPT_NAME}"

print_status "INFO" "Sourcing validation script from ${VALIDATION_SCRIPT}"

if [[ ! -f "$VALIDATION_SCRIPT" ]]; then
    print_status "ERROR" "Validation script not found at ${VALIDATION_SCRIPT}"
    print_status "INFO" "Please run setup-env.sh from the root directory.  Same directory as pom.xml."
    exit 1
else
    print_status "INFO" "Making [${SCRIPT_NAME}] executable..."
    chmod +x "$VALIDATION_SCRIPT"
    

    if [[ -x "$VALIDATION_SCRIPT" ]]; then
        print_status "OK" "Validation script [${SCRIPT_NAME}] is now executable"
    else
        print_status "ERROR" "Failed to make [${SCRIPT_NAME}] executable"
        exit 1
    fi
fi

# setup deploy-dep.sh
# Path to script
SCRIPT_NAME="deploy-dep.sh"
VALIDATION_SCRIPT="${SCRIPT_DIR}/resources/scripts/${SCRIPT_NAME}"

print_status "INFO" "Sourcing validation script from ${VALIDATION_SCRIPT}"

if [[ ! -f "$VALIDATION_SCRIPT" ]]; then
    print_status "ERROR" "Validation script not found at ${VALIDATION_SCRIPT}"
    print_status "INFO" "Please run setup-env.sh from the root directory.  Same directory as pom.xml."
    exit 1
else
    print_status "INFO" "Making [${SCRIPT_NAME}] executable..."
    chmod +x "$VALIDATION_SCRIPT"
    

    if [[ -x "$VALIDATION_SCRIPT" ]]; then
        print_status "OK" "Validation script [${SCRIPT_NAME}] is now executable"
    else
        print_status "ERROR" "Failed to make [${SCRIPT_NAME}] executable"
        exit 1
    fi
fi

# setup build-deploy.sh
# Path to script
SCRIPT_NAME="build-deploy.sh"
VALIDATION_SCRIPT="${SCRIPT_DIR}/resources/scripts/${SCRIPT_NAME}"

print_status "INFO" "Sourcing validation script from ${VALIDATION_SCRIPT}"

if [[ ! -f "$VALIDATION_SCRIPT" ]]; then
    print_status "ERROR" "Validation script not found at ${VALIDATION_SCRIPT}"
    print_status "INFO" "Please run setup-env.sh from the root directory.  Same directory as pom.xml."
    exit 1
else
    print_status "INFO" "Making [${SCRIPT_NAME}] executable..."
    chmod +x "$VALIDATION_SCRIPT"
    

    if [[ -x "$VALIDATION_SCRIPT" ]]; then
        print_status "OK" "Validation script [${SCRIPT_NAME}] is now executable"
    else
        print_status "ERROR" "Failed to make [${SCRIPT_NAME}] executable"
        exit 1
    fi
fi

# setup workshop.sh
# Path to script (local directory)
SCRIPT_NAME="workshop.sh"
VALIDATION_SCRIPT="${SCRIPT_DIR}/${SCRIPT_NAME}"

print_status "INFO" "Sourcing validation script from ${VALIDATION_SCRIPT}"

if [[ ! -f "$VALIDATION_SCRIPT" ]]; then
    print_status "ERROR" "Validation script not found at ${VALIDATION_SCRIPT}"
    print_status "INFO" "Please run setup-env.sh from the root directory.  Same directory as pom.xml."
    exit 1
else
    print_status "INFO" "Making [${SCRIPT_NAME}] executable..."
    chmod +x "$VALIDATION_SCRIPT"
    

    if [[ -x "$VALIDATION_SCRIPT" ]]; then
        print_status "OK" "Validation script [${SCRIPT_NAME}] is now executable"
    else
        print_status "ERROR" "Failed to make [${SCRIPT_NAME}] executable"
        exit 1
    fi
fi

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
fi

