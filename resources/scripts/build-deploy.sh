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
echo -e "${BLUE}  Test Deploy Module Application${NC}"
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

# 2. Build app
#quarkus build --no-tests -Dquarkus.container-image.build=true -Dquarkus.container-image.push=true


# 3. Deploy app
#quarkus deploy openshift

# if you need to clear out old is, bc from another s2i
#oc delete deployment micrometer-module 2>/dev/null || true
#oc delete service micrometer-module 2>/dev/null || true
#oc delete route micrometer-module 2>/dev/null || true
#oc delete bc micrometer-module-build-user1 2>/dev/null || true
#oc delete is micrometer-module 2>/dev/null || true

# 2. Try mvn commands....
# Check appsettings for quarkus container annotations and select the right mvn package
#mvn clean package -DskipTests -Dquarkus.container-image.build=true -Dquarkus.container-image.push=true -Dquarkus.kubernetes.deploy=true -Dquarkus.openshift.annotations.\"sidecar.opentelemetry.io/inject\"=sidecar

# should work on clean environment
mvn clean package -DskipTests

echo ""


