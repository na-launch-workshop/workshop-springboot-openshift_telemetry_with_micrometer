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
echo -e "${BLUE}  Workshop Environment Validation${NC}"
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

# Need to check env variables
# Need to check oc login status
# Need to get versions
# need to get servce the servicemonitor the otelcollector
# Check the project to ensure the user is in the prigght project

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

            OC_USER="kubeadmin"
        fi

    else
        print_status "ERROR" "oc login is not set"
        print_status "INFO" "Please login into OpenShift first: oc login <cluster-url> --token=<your-token>"
        
        exit 1
    fi
fi

print_status "INFO" "User set to: ${OC_USER}" 

echo ""

# TODO clean this up since we are now getting current user above
# 2. Check OpenShift login
echo -e "${YELLOW}2. Checking OpenShift Login...${NC}"

if command -v oc &> /dev/null; then
    print_status "OK" "oc command found"
    
    if oc whoami &> /dev/null; then
        CURRENT_USER=$(oc whoami)
        
        print_status "OK" "Logged into OpenShift as: ${CURRENT_USER}"
        
        CURRENT_PROJECT=$(oc project -q 2>/dev/null || echo "unknown")
        
        print_status "INFO" "Current project: ${CURRENT_PROJECT}"
        
    else
        print_status "ERROR" "Not logged into OpenShift. Run 'oc login' first."
    fi
else
    print_status "ERROR" "oc command not found. OpenShift CLI is not installed."
fi

echo ""

# 3. Check Java version
echo -e "${YELLOW}3. Checking Java Version...${NC}"

if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    
    print_status "OK" "Java found: ${JAVA_VERSION}"
    
    JAVA_MAJOR=$(echo ${JAVA_VERSION} | cut -d'.' -f1)

    if [[ ${JAVA_MAJOR} -ge 17 ]]; then
        print_status "OK" "Java version is 17 or higher"
    else
        print_status "WARNING" "Java version is less than 17. Quarkus recommends Java 17+"
    fi
else
    print_status "ERROR" "java command not found. Java is not installed or not in PATH."
fi

echo ""

# 4. Check Maven version
echo -e "${YELLOW}4. Checking Maven Version...${NC}"

if command -v mvn &> /dev/null; then
    MVN_VERSION=$(mvn -version 2>/dev/null | head -n 1 | awk '{print $3}')
    
    print_status "OK" "Maven found: ${MVN_VERSION}"
    
    MVN_MAJOR=$(echo ${MVN_VERSION} | cut -d'.' -f1)
    
    MVN_MINOR=$(echo ${MVN_VERSION} | cut -d'.' -f2)

    if [[ ${MVN_MAJOR} -gt 3 ]] || [[ ${MVN_MAJOR} -eq 3 && ${MVN_MINOR} -ge 6 ]]; then
        print_status "OK" "Maven version is 3.6 or higher"
    else
        print_status "WARNING" "Maven version is less than 3.6. Consider upgrading for better Quarkus support."
    fi
else
    print_status "ERROR" "mvn command not found. Maven is not installed or not in PATH."
fi

echo ""

# 5. Check Quarkus version
echo -e "${YELLOW}5. Checking Quarkus CLI Version...${NC}"

if command -v quarkus &> /dev/null; then
    QUARKUS_VERSION=$(quarkus version 2>/dev/null)
    if [[ "${QUARKUS_VERSION}" != "unknown" ]]; then
        print_status "OK" "Quarkus CLI found: ${QUARKUS_VERSION}"
    else
        print_status "WARNING" "Quarkus CLI found but version could not be determined"
    fi
else
    print_status "ERROR" "quarkus command not found. Quarkus CLI is not installed or not in PATH."
    print_status "INFO" "Install with: curl -Ls https://sh.jbang.dev | bash -s - trust add https://repo1.maven.org/maven2/io/quarkus/quarkus-cli/"
    print_status "INFO" "Then: curl -Ls https://sh.jbang.dev | bash -s - app install --fresh --force quarkus@quarkusio"
fi

echo ""

# 6. Check project naming convention
echo -e "${YELLOW}6. Checking Current Project...${NC}"

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

echo ""

# not sure exactly what I want to do here long term but basically I want to confirm all ...
# ... dependencies are at least deployed.  if not hte user will need to deploy then.
# 7. Check Required OpenShift Resources
echo -e "${YELLOW}7. Checking Required OpenShift Resources...${NC}"

# a. for Now I want to check if the otel collecotr service just exists or not

SERVICE_NAME="greeting-otel-metrics"

if oc get service "${SERVICE_NAME}" &>/dev/null; then
    print_status "OK" "Service/${SERVICE_NAME} exists"
else
    print_status "ERROR" "Service/${SERVICE_NAME} not found"
fi

SERVICE_MONITOR_NAME="greeting-otel"

# b. Check ServiceMonitor
if oc get servicemonitor "${SERVICE_MONITOR_NAME}" &>/dev/null; then
    print_status "OK" "ServiceMonitor/greeting-otel exists"
else
    print_status "ERROR" "ServiceMonitor/greeting-otel not found"
fi

OTEL_COLL_NAME="sidecar"

# c. check OpenTelemetryCollector
if oc get opentelemetrycollector "${OTEL_COLL_NAME}" &>/dev/null; then
    print_status "OK" "OpenTelemetryCollector/sidecar exists"
else
    print_status "ERROR" "OpenTelemetryCollector/sidecar not found"
fi

echo ""